#!/bin/bash
################################################################################
# wifi_to_eth_router.sh
#
# Purpose:
#   Configure a Raspberry Pi (Raspbian Bookworm/Bullseye) to share its Wi-Fi 
#   (wlan0) internet connection over Ethernet (eth0) using NAT and DHCP.
#   The Pi will act as a router, providing DHCP on eth0 and forwarding to wlan0.
#
# Usage:
#   Run this script as root (sudo). Example:
#     sudo bash wifi_to_eth_router.sh
#   The script installs necessary packages, configures networking, and sets up 
#   NAT forwarding. It is idempotent; safe to run multiple times without 
#   duplicating configurations.
#
# Prerequisites:
#   - Raspberry Pi OS (Debian-based, Bookworm/Bullseye).
#   - Wi-Fi interface (wlan0) must be already connected to the Internet.
#   - Ethernet interface (eth0) is the target for sharing.
#   - Required packages (dnsmasq, iptables-persistent) will be installed if missing.
#   - Must be run as root (sudo).
#
################################################################################

set -euo pipefail

# Variables (modify these if your network requires different settings)
WLAN_IFACE="wlan0"
ETH_IFACE="eth0"
IP_ADDR="192.168.2.1"         # IP address for eth0 (gateway for clients)
CIDR_SUFFIX="24"              # CIDR suffix for eth0 netmask (/24 = 255.255.255.0)
DHCP_RANGE_START="192.168.2.2"
DHCP_RANGE_END="192.168.2.100"
DHCP_LEASE_TIME="24h"
# DNS server(s) to forward queries to (comma-separated)
DNS_SERVERS="8.8.8.8,8.8.4.4"

# Ensure script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root. Use sudo." >&2
    exit 1
fi

# Check that network interfaces exist
if ! ip link show "$WLAN_IFACE" &> /dev/null; then
    echo "Error: Interface $WLAN_IFACE not found." >&2
    exit 1
fi
if ! ip link show "$ETH_IFACE" &> /dev/null; then
    echo "Error: Interface $ETH_IFACE not found." >&2
    exit 1
fi

# Install required packages (dnsmasq and iptables-persistent for saving rules)
echo "Installing required packages..."
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y dnsmasq iptables-persistent

# Backup configuration files before modifying
echo "Backing up configuration files..."
# Backup dnsmasq main config if it exists
if [ -f /etc/dnsmasq.conf ]; then
    cp /etc/dnsmasq.conf /etc/dnsmasq.conf.bak
fi
# Backup any existing dnsmasq config directory (only once)
if [ -d /etc/dnsmasq.d ] && [ ! -d /etc/dnsmasq.d.bak ]; then
    cp -a /etc/dnsmasq.d /etc/dnsmasq.d.bak
fi
# Backup dhcpcd.conf
if [ -f /etc/dhcpcd.conf ]; then
    cp /etc/dhcpcd.conf /etc/dhcpcd.conf.bak
fi
# Backup sysctl.conf
if [ -f /etc/sysctl.conf ]; then
    cp /etc/sysctl.conf /etc/sysctl.conf.bak
fi
# Backup existing iptables rules (if any)
if [ -f /etc/iptables/rules.v4 ]; then
    cp /etc/iptables/rules.v4 /etc/iptables/rules.v4.bak
fi

# Define rollback function to restore backups on error
on_error() {
    echo "An error occurred. Restoring backups..."
    if [ -f /etc/dnsmasq.conf.bak ]; then
        mv /etc/dnsmasq.conf.bak /etc/dnsmasq.conf
    fi
    if [ -d /etc/dnsmasq.d.bak ]; then
        rm -rf /etc/dnsmasq.d
        mv /etc/dnsmasq.d.bak /etc/dnsmasq.d
    fi
    if [ -f /etc/dhcpcd.conf.bak ]; then
        mv /etc/dhcpcd.conf.bak /etc/dhcpcd.conf
    fi
    if [ -f /etc/sysctl.conf.bak ]; then
        mv /etc/sysctl.conf.bak /etc/sysctl.conf
    fi
    if [ -f /etc/iptables/rules.v4.bak ]; then
        mv /etc/iptables/rules.v4.bak /etc/iptables/rules.v4
        # Restore iptables rules
        iptables-restore < /etc/iptables/rules.v4 || true
    fi
    echo "Rollback complete."
    exit 1
}
trap 'on_error' ERR

echo "Configuring network interface $ETH_IFACE..."

# Bring up the ethernet interface and assign static IP
ip link set "$ETH_IFACE" up
# Remove any existing IP addresses on eth0
ip addr flush dev "$ETH_IFACE"
# Assign the static IP address to eth0
ip addr add "${IP_ADDR}/${CIDR_SUFFIX}" dev "$ETH_IFACE"

# Configure dhcpcd to set static IP on eth0 at boot (idempotent check)
if ! grep -q "interface $ETH_IFACE" /etc/dhcpcd.conf; then
    cat <<EOF >> /etc/dhcpcd.conf

interface $ETH_IFACE
static ip_address=${IP_ADDR}/${CIDR_SUFFIX}
# no static routers so that default gateway remains via Wi-Fi
EOF
    echo "Added static IP configuration for $ETH_IFACE to /etc/dhcpcd.conf"
else
    echo "Static IP configuration for $ETH_IFACE already present in dhcpcd.conf, skipping"
fi

# Enable IPv4 forwarding in sysctl.conf (or uncomment if present)
if grep -q "^#*net.ipv4.ip_forward" /etc/sysctl.conf; then
    sed -i 's/^#*net.ipv4.ip_forward=.*/net.ipv4.ip_forward=1/' /etc/sysctl.conf
else
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
fi
# Apply forwarding immediately
sysctl -w net.ipv4.ip_forward=1

echo "Configuring dnsmasq for DHCP on $ETH_IFACE..."

# Stop dnsmasq before reconfiguration
systemctl stop dnsmasq

# Remove old dnsmasq configuration
rm -f /etc/dnsmasq.conf
rm -f /etc/dnsmasq.d/*.conf

# Create new minimal dnsmasq config for DHCP on eth0
cat <<EOF > /etc/dnsmasq.conf
interface=$ETH_IFACE
bind-interfaces
# DNS forwarders (comma-separated)
server=$DNS_SERVERS
# Don't forward domains without a dot
domain-needed
# Don't forward private IP ranges
bogus-priv
# DHCP range and lease time
dhcp-range=${DHCP_RANGE_START},${DHCP_RANGE_END},${DHCP_LEASE_TIME}
EOF

echo "Restarting dnsmasq service..."
systemctl restart dnsmasq

echo "Setting up NAT forwarding with iptables..."

# Flush existing NAT/forward rules to ensure idempotency
iptables -t nat -F
iptables -F FORWARD

# Set up new iptables NAT rules
iptables -t nat -A POSTROUTING -o "$WLAN_IFACE" -j MASQUERADE
iptables -A FORWARD -i "$ETH_IFACE" -o "$WLAN_IFACE" -j ACCEPT
iptables -A FORWARD -i "$WLAN_IFACE" -o "$ETH_IFACE" -m state --state RELATED,ESTABLISHED -j ACCEPT

# Ensure /etc/iptables directory exists for persistent rules
mkdir -p /etc/iptables

# Save iptables rules so they are applied on boot (requires iptables-persistent)
iptables-save > /etc/iptables/rules.v4

echo "Configuration complete. Ethernet $ETH_IFACE should now share Internet from $WLAN_IFACE."
echo "You may need to reboot or reconnect devices to take effect."
