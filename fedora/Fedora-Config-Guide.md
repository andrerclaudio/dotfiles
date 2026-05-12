# Fedora Initial Configuration Guide

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

3. Run the Apps script and restart:

    ```shell
    ./apps.sh
    sudo reboot
    ```

    *Note: From now on, use the Alacritty terminal.*

4. Install Oh My ZSH:
    Open your terminal and run:

    ```shell
    sh -c "$(curl -fsSL [https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh](https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh))"
    ```

    *Note: When the installation finishes, it may drop you into a new ZSH prompt. Type `exit` to return to your normal prompt if needed, and then restart:*

    ```shell
    sudo reboot
    ```

5. Fetch Dotfiles:

    ```shell
    git clone [https://github.com/andrerclaudio/dotfiles.git](https://github.com/andrerclaudio/dotfiles.git) ~/Downloads
    ```

6. Install TPM (Tmux Plugin Manager):

    ```shell
    git clone [https://github.com/tmux-plugins/tpm](https://github.com/tmux-plugins/tpm) ~/.tmux/plugins/tpm
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

3. **Change DNS addresses:**
    Go to Wi-Fi settings, change DNS from automatic to manual, and add:
    - **IPV4:** `8.8.8.8, 8.8.4.4`
    - **IPV6:** `2001:4860:4860::8888, 2001:4860:4860::8844`

## Phase 3: Specialized Software Setup & Tuning

1. **Install Spicetify:**
    *Note: Ensure you have opened the Spotify Flatpak at least once before running this to generate the required folders.*

    ```shell
    curl -fsSL [https://raw.githubusercontent.com/spicetify/cli/main/install.sh](https://raw.githubusercontent.com/spicetify/cli/main/install.sh) | sh
    spicetify
    nano ~/.config/spicetify/config-xpui.ini
    ```

    Add this line to the config: `prefs_path = /home/algernon/.var/app/com.spotify.Client/config/spotify/prefs`

    Apply permissions and inject Spicetify:

    ```shell
    sudo chmod a+wr /var/lib/flatpak/app/com.spotify.Client/x86_64/stable/active/files/extra/share/spotify
    sudo chmod a+wr -R /var/lib/flatpak/app/com.spotify.Client/x86_64/stable/active/files/extra/share/spotify/Apps
    spicetify backup apply
    ```

    Install the GruvBox extension:

    ```shell
    git clone [https://github.com/Skaytacium/Gruvify](https://github.com/Skaytacium/Gruvify) ~/.config/spicetify/Themes/Gruvify
    cd ~/.config/spicetify/Themes/Gruvify
    sudo npm i -g sass
    sass user.sass user.css
    spicetify config current_theme Gruvify
    spicetify apply
    ```

2. **Set up Pueue Daemon:**
    - Download `pueued.service` from the GitHub Releases page.  
    - Place `systemd.pueued.service` in `/usr/lib/systemd/user`.
    - Make sure the `pueued` binary (installed via Cargo) is symlinked or copied to `/usr/bin/`.  
    - Enable the service:

    ```shell
    systemctl --user enable --now systemd.pueued
    sudo systemctl daemon-reload
    systemctl --user status systemd.pueued
    ```

3. **Install Nvidia Drivers (If Needed):**

    ```shell
    sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda xorg-x11-drv-nvidia-cuda-libs nvidia-settings nvidia-persistenced nvidia-modprobe
    ```

4. **Tune VS Code Settings (Inotify limits):**

    ```shell
    sudo nano /etc/sysctl.conf
    ```

    Add `fs.inotify.max_user_watches=524288` at the end of the file and save it. Run the code below to reload the settings:

    ```shell
    sudo sysctl -p
    ```

5. Install your preferred **PWA applications**.
6. Install your preferred **Gnome Extensions**.
