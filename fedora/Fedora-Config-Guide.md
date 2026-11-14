# Fedora Initial Configuration Guide

> Target: Fedora 44 and later (dnf5, GNOME 50+, Wayland-only session).
>
> Each script writes a log to `~/fedora-setup-<stage>.log`. Check it for
> packages DNF could not find.

```text
  Fresh Fedora install
          │
          ▼
  ┌────────────────────────────────────┐
  │ core.sh     repos, upgrade, swap,  │──▶ tools/change_swap.sh
  │             git, wallpapers        │──▶ tools/colors_solid.py
  └────────────────────────────────────┘
          │ reboot
          ▼
  ┌────────────────────────────────────┐
  │ apps.sh     DNF, Flatpak, Snap     │
  └────────────────────────────────────┘
          │ reboot
          ▼
  ┌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┐
  ╎ by hand:    Nvidia driver, reboot  ╎
  ╎             Oh My Zsh, reboot      ╎
  ╎             sign-ins               ╎
  └╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┘
          │
          ▼
  ┌────────────────────────────────────┐
  │ extra.sh    tools, configs, grid   │──▶ tools/gnome_app_grid.sh
  └────────────────────────────────────┘
          │ reboot
          ▼
  ┌────────────────────────────────────┐
  │ desktop.sh  extensions, shortcuts  │
  └────────────────────────────────────┘
          │ reboot
          ▼
  Phases 2-3, by hand
```

## Phase 1: Automated scripts and shell setup

> The stage scripts are already executable; no `chmod` needed.

1. Run the Core script and restart:

    ```shell
    cd ~/dotfiles/fedora   # wherever you cloned the repo
    ./core.sh
    sudo reboot
    ```

    *Reboot so the `dialout` group membership this script grants takes effect.*

    *It also creates a 16 GiB swap file at `/swapfile`, used once zram is full.*

    *And it writes one 1920x1080 PNG per Gruvbox color into `~/Pictures/Solid`
    (`tools/colors_solid.py`), ready to pick as a wallpaper.*

2. Run the Apps script and restart:

    ```shell
    cd ~/dotfiles/fedora
    ./apps.sh
    sudo reboot
    ```

    *Installs apps from DNF, Flathub and Snap, then starts Syncthing.*

    *The Flatpak stage installs one app at a time, printing `[n/total] <app-id>`.*

    *From now on, use the Alacritty or Ghostty terminal.*

3. Install the Nvidia drivers (if needed) and restart:

    ```shell
    sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda xorg-x11-drv-nvidia-cuda-libs nvidia-settings nvidia-persistenced nvidia-modprobe
    ```

    *Wait for the kernel module to finish building before rebooting, or you
    boot to a black screen. Check with:*

    ```shell
    modinfo -F version nvidia
    ```

    *If Secure Boot is enabled, the module must be signed or Secure Boot
    disabled, or it will refuse to load.*

    ```shell
    sudo reboot
    ```

    *Do this before `extra.sh`, or the Ollama install fails.*

4. Install Oh My ZSH:
    Open your terminal and run:

    ```shell
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    ```

    *If it leaves you in a new ZSH prompt, type `exit`, then restart:*

    ```shell
    sudo reboot
    ```

5. Start your personal accounts:
    - Open Google Chrome and log in.
    - Go to GitHub and log in.
    - Open VS Code and start Sync.

6. Run the Extra script and restart:

    ```shell
    cd ~/dotfiles/fedora
    ./extra.sh
    sudo reboot
    ```

    *Only steps 1-2 run with sudo.*

    *It replaces `~/.zshrc`, keeping the old one as `~/.zshrc.bak`.*

    *The Ollama models and the Distrobox containers are the slow steps.*

    *The first `distrobox enter` of each container takes a few minutes.*

    *To undo the app grid layout:*

    ```shell
    cd ~/dotfiles/fedora
    ../tools/gnome_app_grid.sh --revert
    ```

7. Run the Desktop script and restart. Use a terminal inside the GNOME
   session, not SSH or a TTY:

    ```shell
    cd ~/dotfiles/fedora
    ./desktop.sh
    sudo reboot
    ```

    *The extensions it installs start after the reboot, with default settings.*

## Phase 2: Logins and network settings

1. Log into Atuin:

    ```shell
    atuin login -u andrerc-outlook
    ```

2. Change the DNS addresses:
    Go to Wi-Fi settings, change DNS from automatic to manual, and add:
    - IPv4: `8.8.8.8, 8.8.4.4`
    - IPv6: `2001:4860:4860::8888, 2001:4860:4860::8844`

## Phase 3: Checks and extras

1. Check the inotify limit (VS Code):
    `core.sh` already writes `/etc/sysctl.d/99-inotify.conf` and applies it.
    Confirm it stuck:

    ```shell
    sysctl fs.inotify.max_user_watches
    ```

    *Should print `524288`. If it prints the default, re-run `sudo sysctl --system`.*

2. Install your preferred PWA applications.

    *To list the Gmail PWA as a Mail app, run this, and again if Chrome drops it:*

    ```shell
    cd ~/dotfiles/fedora
    ../tools/gmail_pwa_mailto.sh
    ```

3. Install any other GNOME extensions you want, on top of the ones
   `desktop.sh` installs.

4. Initialize the tmux plugins:
    Open a tmux session and press `prefix + I` (default prefix: `Ctrl+b`) to
    install the plugins listed in `tmux.conf`.

    *Needs the TPM clone that `extra.sh` installs.*
