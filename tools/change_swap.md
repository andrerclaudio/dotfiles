# Changing SWAP size on a Fedora machine

Create a persistent swap file at `/swapfile` on a freshly installed machine.
Run the steps in order, as root (`sudo` is already in each command). Written
for Btrfs, the Fedora default - for ext4/XFS see the notes at the end.

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
findmnt -no FSTYPE /
```

`df` must show at least `SIZE_GIB` free, and `findmnt` must print `btrfs`.

## 2. Create the swap file

One command does it all: creates the file, turns off copy-on-write, locks the
permissions to `600`, allocates the space and formats it as swap. Takes a few
seconds.

```shell
sudo btrfs filesystem mkswapfile --size "${SIZE_GIB}g" /swapfile
```

## 3. Label it for SELinux - before enabling it

With SELinux enforcing, `swapon` on a file carrying the wrong type is denied, so
this has to happen before step 4.

```shell
# install semanage if missing
sudo dnf install -y policycoreutils-python-utils
sudo semanage fcontext -a -t swapfile_t '/swapfile'
sudo restorecon -v /swapfile
```

## 4. Enable it

```shell
sudo swapon /swapfile
```

## 5. Verify

```shell
swapon --show
free -h
```

`swapon --show` should list `/swapfile` at the new size.

## 6. Make it survive a reboot

```shell
sudo cp /etc/fstab /etc/fstab.bak
echo '/swapfile none swap sw,nofail,x-systemd.device-timeout=1s 0 0' | sudo tee -a /etc/fstab
sudo systemctl daemon-reload
```

`nofail` keeps a missing swap file from blocking boot; `daemon-reload` lets
systemd pick up the entry without a reboot.

## 7. Confirm the fstab entry actually works

```shell
sudo swapoff /swapfile
sudo swapon -a
swapon --show
```

If `/swapfile` comes back in that last listing, the entry is good and the next
boot will do the same thing.

---

## Notes

- **Btrfs**: keep the swap file out of any subvolume you snapshot (Snapper,
  Timeshift) - Btrfs refuses to snapshot a subvolume with an active swap file.
- **ext4/XFS**: `btrfs filesystem mkswapfile` only works on Btrfs. Replace
  step 2 with:

  ```shell
  sudo fallocate -l "${SIZE_GIB}G" /swapfile
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  ```
