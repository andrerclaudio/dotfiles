#!/bin/bash
# Shares a Raspberry Pi's Wi-Fi over eth0 with NetworkManager (Pi OS Bookworm+).
# Run: sudo bash wifi_to_eth_router.sh   Undo: sudo nmcli connection delete eth-share

set -euo pipefail

# Variables (modify these if your network requires different settings)
ETH_IFACE="eth0"
CON_NAME="eth-share"
IP_ADDR="192.168.2.1/24"         # eth0's address, the gateway for clients
DNS_SERVERS="8.8.8.8 8.8.4.4"    # where the Pi forwards the clients' DNS queries

if [ "$(id -u)" -ne 0 ]; then
    echo "Error: run this as root. Use sudo." >&2
    exit 1
fi

if ! systemctl is-active --quiet NetworkManager; then
    echo "Error: NetworkManager is not running." >&2
    exit 1
fi

if ! ip link show "$ETH_IFACE" &>/dev/null; then
    echo "Error: interface $ETH_IFACE not found." >&2
    exit 1
fi

# Shared mode runs its own dnsmasq; dnsmasq-base is the binary without a service.
echo "Installing dnsmasq-base..."
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y dnsmasq-base

# A standalone dnsmasq service holds the DHCP port NetworkManager needs.
if systemctl is-active --quiet dnsmasq; then
    echo "Stopping the standalone dnsmasq service..."
    systemctl disable --now dnsmasq
fi

# Clients use the Pi as their DNS server; the Pi forwards to DNS_SERVERS.
echo "Writing the DNS settings..."
mkdir -p /etc/NetworkManager/dnsmasq-shared.d
{
    echo "no-resolv"
    for dns in $DNS_SERVERS; do
        echo "server=$dns"
    done
    echo "domain-needed"    # don't forward names without a dot
    echo "bogus-priv"       # don't forward reverse lookups of private IPs
} > /etc/NetworkManager/dnsmasq-shared.d/eth-share.conf

# Recreated each run; the priority beats the default "Wired connection 1".
echo "Creating the $CON_NAME connection on $ETH_IFACE..."
nmcli connection delete "$CON_NAME" &>/dev/null || true
nmcli connection add type ethernet ifname "$ETH_IFACE" con-name "$CON_NAME" \
    ipv4.method shared ipv4.addresses "$IP_ADDR" \
    connection.autoconnect-priority 100

# Without a cable this fails, but the saved profile comes up once eth0 has a link.
if nmcli connection up "$CON_NAME"; then
    echo "Done. Devices on $ETH_IFACE now get an address and internet from the Pi."
else
    echo "Saved, but not active yet (is the cable plugged in?). It starts once $ETH_IFACE has a link."
fi
