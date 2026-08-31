# Fedora Initial Configuration Guide

> **Target: Fedora 44 and later** (dnf5, GNOME 50+, Wayland-only session).
>
> **Run order matters.** `core.sh` → `apps.sh` → **Oh My Zsh** → `extra.sh`.
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

    *The reboot is not optional: the `tty` and `dialout` group memberships this
    script grants only take effect after a full logout.*

3. Run the Apps script and restart:

    ```shell
    ./apps.sh
    sudo reboot
    ```

    *This installs from two sources: DNF (including the COPRs, Chrome, and
    VS Code from Microsoft's own RPM repo) and Flathub (`--user`).*

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

5. **Start your personal accounts:**
    - Open **Google Chrome** and log in.
    - Go to **GitHub** and log in.
    - Open **VS Code** and start Sync.

6. Run the Extra script (Plugins, Fonts, Cargo, Zed, Ollama, Herdr, Antigravity
   CLI, configs, TPM) and restart:

    ```shell
    ./extra.sh
    sudo reboot
    ```

7. **Install the ZSH config:**
    Overwrite the `~/.zshrc` the Oh My Zsh installer wrote:

    ```shell
    cp config/zsh/.zshrc ~/.zshrc
    ```

## Phase 2: Manual Authentications & GUI Tweaks

1. **Log into Atuin:**

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

1. **Start the Pueue Daemon:**
    The unit is already at `~/.config/systemd/user/pueued.service`, pointing at
    `%h/.cargo/bin/pueued` (the Cargo-installed binary — there is no
    `/usr/bin/pueued` on this system). Reload first, then enable
    (`daemon-reload` before `enable`, not after):

    ```shell
    systemctl --user daemon-reload
    systemctl --user enable --now pueued
    systemctl --user status pueued
    ```

2. **Install Nvidia Drivers (If Needed):**

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

3. **Tune VS Code Settings (Inotify limits):**
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

4. Install your preferred **PWA applications**.
5. Install your preferred **Gnome Extensions**.

6. **Initialize Tmux Plugins:**
    Open a Tmux session and press `prefix + I` (default prefix: `Ctrl+b`) to
    install the plugins listed in `tmux.conf`.

    *`prefix + I` does nothing at all unless both halves are in place:
    `~/.config/tmux/tmux.conf`, and the TPM clone at `~/.tmux/plugins/tpm` that
    the last line of that file runs.
