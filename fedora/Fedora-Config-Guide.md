# Fedora Initial Configuration Guide

> **Run order matters.** `core.sh` → `apps.sh` → **Oh My Zsh** → `extra.sh`.
> `apps.sh` installs the `-devel` packages that the Rust crates in `extra.sh`
> compile against, and `extra.sh` writes into `~/.oh-my-zsh/custom`. Running
> `extra.sh` early fails on both counts.
>
> Each script writes a log to `~/fedora-setup-<stage>.log` — check it for
> packages DNF could not find.

## Phase 1: Automated Scripts & Shell Setup

1. Make all installation files executable:

    ```shell
    chmod +x core.sh apps.sh extra.sh
    ```

2. Run the Core script and restart:

    ```shell
    ./core.sh
    sudo reboot
    ```

    *The reboot is required: the `tty` and `dialout` group memberships added by
    the script only take effect after a full logout.*

3. Run the Apps script and restart:

    ```shell
    ./apps.sh
    sudo reboot
    ```

    *Note: From now on, use the Alacritty or Ghostty terminal.*

4. Install Oh My ZSH:
    Open your terminal and run:

    ```shell
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    ```

    *Note: When the installation finishes, it may drop you into a new ZSH prompt. Type `exit` to return to your normal prompt if needed, and then restart:*

    ```shell
    sudo reboot
    ```

5. Fetch Dotfiles:

    ```shell
    git clone https://github.com/andrerclaudio/dotfiles.git ~/Downloads/dotfiles
    ```

    *The clone target must be an empty or non-existent directory — cloning
    straight into `~/Downloads` fails once anything else is in there.*

6. Install TPM (Tmux Plugin Manager):

    ```shell
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    ```

7. **Initialize Tmux Plugins:**
    After moving your Tmux dotfile from your cloned repository to its place inside the `~/.config` folder, enter a Tmux environment and press `prefix + I` to install the plugins.

8. Run the Extra script (Plugins, Fonts, Cargo, etc.) and restart:

    ```shell
    ./extra.sh
    sudo reboot
    ```

## Phase 2: Manual Authentications & GUI Tweaks

1. **Start your personal accounts:**
    - Open **Google Chrome** and log in.
    - Go to **GitHub** and log in.
    - Open **VS Code** and start Sync.
    - Run the following command to log into Atuin:

      ```shell
      atuin login -u andrerc-outlook
      ```

2. **Apply Gnome Tweaks:**
    Open the Gnome Tweaks application and apply the following settings downloaded by the scripts:
    - **Fonts:** `JetBrainsMonoNL Nerd Font Mono`
    - **Appearance (Icons):** `Gruvbox-Plus-Dark`

    *If the font doesn't appear in the list, run `fc-cache -f` and reopen Tweaks.*

3. **Change DNS addresses:**
    Go to Wi-Fi settings, change DNS from automatic to manual, and add:
    - **IPV4:** `8.8.8.8, 8.8.4.4`
    - **IPV6:** `2001:4860:4860::8888, 2001:4860:4860::8844`

## Phase 3: Specialized Software Setup & Tuning

1. **Install Spicetify:**
    *Note: Spotify is installed as a Flatpak by `apps.sh`. Open it at least once before running this, so the required folders exist.*

    ```shell
    curl -fsSL https://raw.githubusercontent.com/spicetify/cli/main/install.sh | sh
    spicetify
    nano ~/.config/spicetify/config-xpui.ini
    ```

    Add this line to the config (`$HOME` written out, since the file is not shell-expanded):

    ```ini
    prefs_path = /home/algernon/.var/app/com.spotify.Client/config/spotify/prefs
    ```

    Apply permissions and inject Spicetify:

    ```shell
    SPOTIFY_DIR=/var/lib/flatpak/app/com.spotify.Client/x86_64/stable/active/files/extra/share/spotify
    sudo chmod a+wr "$SPOTIFY_DIR"
    sudo chmod a+wr -R "$SPOTIFY_DIR/Apps"
    spicetify backup apply
    ```

    Install the GruvBox extension (`npm` comes from `apps.sh`):

    ```shell
    git clone https://github.com/Skaytacium/Gruvify ~/.config/spicetify/Themes/Gruvify
    cd ~/.config/spicetify/Themes/Gruvify
    sudo npm i -g sass
    sass user.sass user.css
    spicetify config current_theme Gruvify
    spicetify apply
    ```

2. **Set up Pueue Daemon:**
    - The unit file ships in the dotfiles repo as `systemd.pueued.service`.
      Copy it into `~/.config/systemd/user/` **and rename it:

      ```shell
      mkdir -p ~/.config/systemd/user
      cp ~/Downloads/dotfiles/systemd.pueued.service ~/.config/systemd/user/pueued.service
      ```

      *User units belong under `$HOME`; `/usr/lib/systemd/user` is
      package-owned and gets overwritten on updates.*

    - Point `ExecStart` at the Cargo-installed binary. The shipped unit calls
      `/usr/bin/pueued`, which does not exist on this system:

      ```shell
      sed -i 's|^ExecStart=.*|ExecStart=%h/.cargo/bin/pueued -vv|' ~/.config/systemd/user/pueued.service
      grep ExecStart ~/.config/systemd/user/pueued.service
      ```

    - Reload first, then enable (`daemon-reload` before `enable`, not after):

      ```shell
      systemctl --user daemon-reload
      systemctl --user enable --now pueued
      systemctl --user status pueued
      ```

3. **Install Nvidia Drivers (If Needed):**

    ```shell
    sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda xorg-x11-drv-nvidia-cuda-libs nvidia-settings nvidia-persistenced nvidia-modprobe
    ```

    *Wait for the kernel module to finish building before rebooting — otherwise
    you boot to a black screen. Check with:*

    ```shell
    modinfo -F version nvidia
    ```

    *If Secure Boot is enabled, the module must be signed or Secure Boot
    disabled, or it will refuse to load.*

4. **Tune VS Code Settings (Inotify limits):**
    Use a drop-in file rather than editing `/etc/sysctl.conf` (deprecated, and
    replaced on some upgrades):

    ```shell
    echo "fs.inotify.max_user_watches=524288" | sudo tee /etc/sysctl.d/99-inotify.conf
    sudo sysctl --system
    ```

    Verify:

    ```shell
    sysctl fs.inotify.max_user_watches
    ```

5. Install your preferred **PWA applications**.
6. Install your preferred **Gnome Extensions**.
