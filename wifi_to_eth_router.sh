#!/bin/bash
# wifi_to_eth_router.sh
# This script configures a Raspberry Pi to share its Wi-Fi (wlan0) internet
# connection over Ethernet (eth0) via NAT/DHCP.

set -e

# 1. Update package lists and install required packages
echo "Updating apt and installing dnsmasq and iptables-persistent..."
apt-get update
# Pre-seed iptables-persistent to auto-save IPv4 rules, disable IPv6 prompt
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean false | debconf-set-selections
apt-get install -y dnsmasq iptables-persistent

# 2. Configure a static IP for eth0 in /etc/dhcpcd.conf
#    This sets eth0 to 192.168.2.1/24 and prevents it from setting a default gateway.
echo "Configuring static IP for eth0..."
cat <<EOF >> /etc/dhcpcd.conf

interface eth0
static ip_address=192.168.2.1/24
nogateway
EOF

# 3. Configure dnsmasq to provide DHCP on eth0
echo "Backing up original dnsmasq config and creating new one..."
mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig 2>/dev/null || true
cat <<EOF > /etc/dnsmasq.conf
interface=eth0        # Listen on eth0
server=8.8.8.8        # Use Google DNS
domain-needed         # Only forward DNS queries with a domain part
bogus-priv            # Do not forward non-routable addresses
dhcp-range=192.168.2.50,192.168.2.100,12h  # DHCP range and lease time
EOF

# 4. Enable IPv4 forwarding in the kernel
echo "Enabling IPv4 forwarding..."
# Uncomment net.ipv4.ip_forward if it exists, else append
if grep -q '^#\?net.ipv4.ip_forward' /etc/sysctl.conf; then
    sed -i 's/^#\?net.ipv4.ip_forward=.*/net.ipv4.ip_forward=1/' /etc/sysctl.conf
else
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
fi
sysctl -w net.ipv4.ip_forward=1

# 5. Set up iptables NAT (masquerade) rules
echo "Setting up iptables rules for NAT..."
iptables -F
iptables -t nat -F
iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
iptables -A FORWARD -i wlan0 -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth0 -o wlan0 -j ACCEPT

# 6. Save the iptables rules so they persist across reboots
echo "Saving iptables rules..."
iptables-save > /etc/iptables/rules.v4

# 7. Restart dnsmasq to apply new config
echo "Restarting dnsmasq service..."
systemctl restart dnsmasq

echo "Configuration complete. Reboot the Raspberry Pi to apply changes."
