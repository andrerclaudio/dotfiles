# Changing SWAP size on a Fedora machine

Create a persistent swap file at `/swapfile` on a freshly installed machine.
Run the steps in order, as root (`sudo` is already in each command). Works on
Btrfs (the Fedora default) and on ext4/XFS.

Pick the size once and reuse it through the rest of the guide:

```shell
SIZE_GIB=16
```

Keep the same shell open for every step, or set `SIZE_GIB` again if you come
back later.

---

## 1. Look at what is already there

```shell
swapon --show
free -h
df -h /
```

`df` must show at least `SIZE_GIB` free.

## 2. Create the empty file, disable copy-on-write, lock down permissions

Order matters: on Btrfs, `chattr +C` only takes effect while the file is still
empty. On ext4/XFS the command fails harmlessly - carry on.

```shell
sudo touch /swapfile
sudo chattr +C /swapfile
sudo chmod 600 /swapfile
```

## 3. Allocate the space

Zeros, not `fallocate`: on Btrfs `fallocate` leaves holes behind and `mkswap`
rejects a file with holes. This takes a while.

```shell
sudo dd if=/dev/zero of=/swapfile bs=1M count=$((SIZE_GIB * 1024)) status=progress conv=fdatasync
```

## 4. Label it for SELinux - before enabling it

With SELinux enforcing, `swapon` on a file carrying the wrong type is denied, so
this has to happen before step 5.

```shell
# install semanage if missing
sudo dnf install -y policycoreutils-python-utils
sudo semanage fcontext -a -t swapfile_t '/swapfile'
sudo restorecon -v /swapfile
```

## 5. Mark as swap and enable it

```shell
sudo mkswap /swapfile
sudo swapon /swapfile
```

## 6. Verify

```shell
swapon --show
free -h
```

`swapon --show` should list `/swapfile` at the new size.

## 7. Make it survive a reboot

```shell
sudo cp /etc/fstab /etc/fstab.bak
echo '/swapfile none swap sw,nofail,x-systemd.device-timeout=1s 0 0' | sudo tee -a /etc/fstab
sudo systemctl daemon-reload
```

`nofail` keeps a missing swap file from blocking boot; `daemon-reload` lets
systemd pick up the entry without a reboot.

## 8. Confirm the fstab entry actually works

```shell
sudo swapoff /swapfile
sudo swapon -a
swapon --show
```

If `/swapfile` comes back in that last listing, the entry is good and the next
boot will do the same thing.

---

## Notes

- **Btrfs**: the swap file must stay NOCOW, uncompressed, and outside any
  snapshotted subvolume - a snapshot of an active swap file will break it.
