# Changing SWAP size in Fedora machine

## Steps (commands) to make `/swapfile` 64 GiB and persistent.  Run each line as root (prefix with sudo if you’re non-root). Do them in order  

```shell
# optional: show current swap
swapon --show
free -h
# create empty file, disable CoW, set permissions
sudo touch /swapfile
sudo chattr +C /swapfile
sudo chmod 600 /swapfile
# allocate 128 GiB by writing zeros (this forces real allocation)
sudo dd if=/dev/zero of=/swapfile bs=1M count=$((64*1024)) status=progress conv=fdatasync
# mark as swap and enable immediately
sudo mkswap /swapfile
sudo swapon /swapfile
# verify
swapon --show
free -h
# install semanage if missing
sudo dnf install -y policycoreutils-python-utils
# label the file and restore SELinux context
sudo semanage fcontext -a -t swapfile_t '/swapfile'
sudo restorecon -v /swapfile
# add to fstab
echo '/swapfile none swap sw,nofail,x-systemd.device-timeout=1s 0 0' | sudo tee -a /etc/fstab
```
