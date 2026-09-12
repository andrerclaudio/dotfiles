#!/bin/bash
################################################################################
# change_swap.sh
#
# Purpose:
#   Create - or resize - a persistent swap file on a Fedora machine. The size is
#   not baked into the steps: set SWAP_SIZE_GIB below and run the script.
#
# Usage:
#   Edit SWAP_SIZE_GIB (and SWAP_FILE, if you want it somewhere else), then:
#     sudo bash change_swap.sh
#
# Prerequisites:
#   - Fedora (uses dnf to pull in semanage when SELinux is enabled).
#   - Free space on the filesystem holding SWAP_FILE, at least SWAP_SIZE_GIB.
#   - Must be run as root (sudo).
#
# Notes:
#   - Safe to re-run: an existing swap file is switched off and rebuilt at the
#     new size, and the /etc/fstab entry and SELinux rule are added only once.
#     Re-running with a different SWAP_SIZE_GIB is how you resize.
#   - Works on Btrfs (the Fedora default) and on ext4/XFS.
#
################################################################################

set -euo pipefail

# Variables (this is the only part you normally edit)
SWAP_SIZE_GIB=64              # how much swap to create, in GiB
SWAP_FILE="/swapfile"         # where the swap file lives

# fstab options: nofail keeps a missing swap file from blocking boot.
FSTAB_OPTS="sw,nofail,x-systemd.device-timeout=1s"

# Ensure the size is a positive whole number of GiB
if ! [[ "$SWAP_SIZE_GIB" =~ ^[0-9]+$ ]] || ((SWAP_SIZE_GIB < 1)); then
    echo "Error: SWAP_SIZE_GIB must be a positive integer, got '$SWAP_SIZE_GIB'." >&2
    exit 1
fi

# Ensure script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root. Use sudo." >&2
    exit 1
fi

echo "Target: ${SWAP_SIZE_GIB} GiB of swap at ${SWAP_FILE}"

# Show what is in use before touching anything
echo "Current swap:"
swapon --show || true
free -h

# Check free space before destroying the old file. The space the current swap
# file occupies counts towards the total, since it is about to be reclaimed.
needed_kib=$((SWAP_SIZE_GIB * 1024 * 1024))
avail_kib=$(df -k --output=avail "$(dirname "$SWAP_FILE")" | tail -n1 | tr -d ' ')
current_kib=0
if [ -f "$SWAP_FILE" ]; then
    current_kib=$(du -k --apparent-size "$SWAP_FILE" | cut -f1)
fi

if ((needed_kib > avail_kib + current_kib)); then
    echo "Error: need $((needed_kib / 1024 / 1024)) GiB but only" \
         "$(((avail_kib + current_kib) / 1024 / 1024)) GiB is available on" \
         "$(dirname "$SWAP_FILE")." >&2
    exit 1
fi

# Switch off and remove the old file, if there is one
if swapon --show=NAME --noheadings | grep -qxF "$SWAP_FILE"; then
    echo "Disabling the active swap file..."
    swapoff "$SWAP_FILE"
fi
rm -f "$SWAP_FILE"

# Create the empty file and disable copy-on-write BEFORE any data goes in:
# on Btrfs, chattr +C only takes effect while the file is still empty. The
# command is a no-op error on ext4/XFS, which is why the failure is tolerated.
echo "Creating ${SWAP_FILE}..."
touch "$SWAP_FILE"
chattr +C "$SWAP_FILE" 2>/dev/null || echo "  (no-CoW not supported here, continuing)"
chmod 600 "$SWAP_FILE"

# Write zeros rather than fallocate: mkswap rejects a file with holes, which is
# what fallocate leaves behind on Btrfs.
echo "Allocating ${SWAP_SIZE_GIB} GiB (this takes a while)..."
dd if=/dev/zero of="$SWAP_FILE" bs=1M count=$((SWAP_SIZE_GIB * 1024)) \
    status=progress conv=fdatasync

# Label the file before enabling it: with SELinux enforcing, swapon on a file
# carrying the wrong type is denied.
if command -v selinuxenabled >/dev/null && selinuxenabled; then
    if ! command -v semanage >/dev/null; then
        echo "Installing semanage..."
        dnf install -y policycoreutils-python-utils
    fi
    # -a refuses a path that is already mapped, so fall back to -m instead of
    # parsing 'semanage fcontext -l'. Either branch ends at swapfile_t, which is
    # what makes a re-run safe.
    echo "Labelling ${SWAP_FILE} as swapfile_t..."
    semanage fcontext -a -t swapfile_t "$SWAP_FILE" 2>/dev/null \
        || semanage fcontext -m -t swapfile_t "$SWAP_FILE"
    restorecon -v "$SWAP_FILE"
fi

echo "Marking as swap and enabling..."
mkswap "$SWAP_FILE"
swapon "$SWAP_FILE"

# Make it persistent. Match on the first field so a resize does not append a
# second entry for the same file.
if awk -v p="$SWAP_FILE" '$1 == p {found = 1} END {exit !found}' /etc/fstab; then
    echo "/etc/fstab already lists ${SWAP_FILE}, leaving it alone."
else
    echo "Adding ${SWAP_FILE} to /etc/fstab (backup at /etc/fstab.bak)..."
    cp /etc/fstab /etc/fstab.bak
    printf '%s none swap %s 0 0\n' "$SWAP_FILE" "$FSTAB_OPTS" >> /etc/fstab
    # Let systemd pick up the new entry without a reboot.
    systemctl daemon-reload
fi

echo
echo "Done. Swap now in use:"
swapon --show
free -h
