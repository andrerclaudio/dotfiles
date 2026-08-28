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

    *If the script stops with `DO NOT REBOOT` and a list of missing desktop
    packages, reinstall them first — rebooting without `gdm` or `gnome-shell`
    leaves you with no graphical session.*

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

    *`extra.sh` (step 9) is what installs Atuin, so its login is in Phase 2.*

6. Fetch Dotfiles:

    ```shell
    git clone https://github.com/andrerclaudio/dotfiles.git ~/Downloads/dotfiles
    ```

    *The clone target must be an empty or non-existent directory — cloning
    straight into `~/Downloads` fails once anything else is in there.*

7. Install TPM (Tmux Plugin Manager):

    ```shell
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    ```

8. **Initialize Tmux Plugins:**
    `tmux.conf` ships in the dotfiles repo (step 6); nothing copies it into
    place, so do that first — tmux reads `~/.config/tmux/tmux.conf`, not the
    clone:

    ```shell
    mkdir -p ~/.config/tmux
    cp ~/Downloads/dotfiles/tmux/tmux.conf ~/.config/tmux/tmux.conf
    ```

    Then enter a Tmux session and press `prefix + I` (default prefix: `Ctrl+b`)
    to install the plugins.

    *The last line of `tmux.conf` runs TPM from `~/.tmux/plugins/tpm`, which is
    exactly where step 7 clones it — if that clone was skipped, `prefix + I`
    does nothing at all.*

9. Run the Extra script (Plugins, Fonts, Cargo, Zed, Ollama) and restart:

    ```shell
    ./extra.sh
    sudo reboot
    ```

## Phase 2: Manual Authentications & GUI Tweaks

1. **Log into Atuin:**

    ```shell
    atuin login -u andrerc-outlook
    ```

    *`extra.sh` installs Atuin, so this only works once Phase 1 step 9 has run.
    If the command is not found, open a new shell first — the installer adds
    `~/.atuin/bin` to `PATH` via `.zshrc`.*

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

1. **Set up Pueue Daemon:**
    - The unit file ships in the dotfiles repo as `systemd.pueued.service`,
      already pointing at `%h/.cargo/bin/pueued` (the Cargo-installed binary —
      there is no `/usr/bin/pueued` on this system). Copy it into
      `~/.config/systemd/user/` **and rename it**:

      ```shell
      mkdir -p ~/.config/systemd/user
      cp ~/Downloads/dotfiles/systemd.pueued.service ~/.config/systemd/user/pueued.service
      ```

      *User units belong under `$HOME`; `/usr/lib/systemd/user` is
      package-owned and gets overwritten on updates.*

    - Reload first, then enable (`daemon-reload` before `enable`, not after):

      ```shell
      systemctl --user daemon-reload
      systemctl --user enable --now pueued
      systemctl --user status pueued
      ```

      *A `status=203/EXEC` failure means `cargo install pueue` did not finish —
      check `~/fedora-setup-extra.log`.*

    - Optional: keep the daemon running when you are not logged in:

      ```shell
      loginctl enable-linger "$USER"
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
