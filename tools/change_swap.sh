#!/bin/bash
# Creates a persistent swap file at /swapfile on Btrfs; skips if it exists. Run as your user.

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

# semanage for step 3, installed first so a failure leaves nothing half done.
sudo dnf install -y policycoreutils-python-utils

# 2. Create the swap file (mkswapfile also disables copy-on-write and sets mode 600)
echo "---> Creating a ${SIZE_GIB} GiB /swapfile..."
sudo btrfs filesystem mkswapfile --size "${SIZE_GIB}g" /swapfile

# 3. Label it for SELinux - swapon is denied without it
echo "---> Labelling /swapfile for SELinux..."
# -m if the rule already exists.
sudo semanage fcontext -a -t swapfile_t '/swapfile' 2>/dev/null \
    || sudo semanage fcontext -m -t swapfile_t '/swapfile'
sudo restorecon -v /swapfile

# 4. Enable it
sudo swapon /swapfile

# 5. Make it survive a reboot (nofail: a missing file never blocks boot)
if ! grep -q '^/swapfile ' /etc/fstab; then
    echo "---> Adding /swapfile to /etc/fstab..."
    sudo cp /etc/fstab /etc/fstab.bak
    echo '/swapfile none swap sw,nofail,x-systemd.device-timeout=1s 0 0' | sudo tee -a /etc/fstab
    sudo systemctl daemon-reload
fi

# 6. Confirm the fstab entry works
sudo swapoff /swapfile
sudo swapon -a
if ! swapon --show=NAME --noheadings --raw | grep -qx /swapfile; then
    echo "!!! /swapfile did not come back from /etc/fstab - check the entry."
    exit 1
fi

swapon --show
