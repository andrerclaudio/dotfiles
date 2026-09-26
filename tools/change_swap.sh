#!/bin/bash
################################################################################
# change_swap.sh
#
# Creates a persistent swap file at /swapfile on a freshly installed machine.
# Written for Btrfs, the Fedora default. Does nothing if /swapfile already
# exists. core.sh runs it; on its own, run it as your normal user:
#
#   bash change_swap.sh
#
# Keep the swap file out of any subvolume you snapshot (Snapper, Timeshift) -
# Btrfs refuses to snapshot a subvolume with an active swap file.
################################################################################

# -e: each step needs the one before it.
set -euo pipefail

SIZE_GIB=16

# 1. Check what is already there
if [[ -e /swapfile ]]; then
    echo "---> /swapfile already exists - nothing to do."
    exit 0
fi

if [[ "$(findmnt -no FSTYPE /)" != btrfs ]]; then
    echo "!!! / is not Btrfs - 'btrfs filesystem mkswapfile' only works there."
    exit 1
fi

if (($(df --output=avail -B1 / | tail -n 1) < SIZE_GIB << 30)); then
    echo "!!! Less than ${SIZE_GIB} GiB free on /."
    exit 1
fi

# semanage, for step 3. Installed before the file exists, so a failure here
# leaves nothing half done.
sudo dnf install -y policycoreutils-python-utils

# 2. Create the swap file
# One command: creates the file, turns off copy-on-write, sets mode 600,
# allocates the space and formats it as swap.
echo "---> Creating a ${SIZE_GIB} GiB /swapfile..."
sudo btrfs filesystem mkswapfile --size "${SIZE_GIB}g" /swapfile

# 3. Label it for SELinux - before enabling it
# With SELinux enforcing, swapon on a file of the wrong type is denied.
# -m when an earlier /swapfile already left the rule behind.
echo "---> Labelling /swapfile for SELinux..."
sudo semanage fcontext -a -t swapfile_t '/swapfile' 2>/dev/null \
    || sudo semanage fcontext -m -t swapfile_t '/swapfile'
sudo restorecon -v /swapfile

# 4. Enable it
sudo swapon /swapfile

# 5. Make it survive a reboot
# nofail keeps a missing swap file from blocking boot; daemon-reload lets
# systemd pick up the entry without a reboot.
if ! grep -q '^/swapfile ' /etc/fstab; then
    echo "---> Adding /swapfile to /etc/fstab..."
    sudo cp /etc/fstab /etc/fstab.bak
    echo '/swapfile none swap sw,nofail,x-systemd.device-timeout=1s 0 0' | sudo tee -a /etc/fstab
    sudo systemctl daemon-reload
fi

# 6. Confirm the fstab entry actually works
# If /swapfile comes back from fstab, the next boot will do the same thing.
sudo swapoff /swapfile
sudo swapon -a
if ! swapon --show=NAME --noheadings --raw | grep -qx /swapfile; then
    echo "!!! /swapfile did not come back from /etc/fstab - check the entry."
    exit 1
fi

swapon --show
