# Fedora Initial Configuration Guide

## This file is intended to guide you through the initial Fedora configuration

1. Make all files executable:

    ```shell
    chmod +x by-dnf.sh
    chmod +x by-flatpak.sh
    chmod +x by-snap.sh
    chmod +x core.sh
    ```

2. Run core.sh:

    ```shell
    ./core.sh
    ```

3. Run by-flatpak.sh:

    ```shell
    ./by-flatpak.sh
    ```

4. Run by-dnf.sh:

    ```shell
    ./by-dnf.sh
    ```

5. Restart the PC:

    ```shell
    sudo reboot
    ```

6. Install Oh My ZSH:

    ```shell
    sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"
    ```

7. Start the personal accounts:

    - Open Google Chrome and log-in.
    - Go to GitHub and log-in.
    - Open VsCode and start Sync.

8. Install Nerd Fonts:

    ```shell
    cd Downloads
    mkdir JetBrainsMono
    curl -OL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz
    tar -xvf JetBrainsMono.tar.xz -C ./JetBrainsMono
    cd
    mkdir .fonts
    mv Downloads/JetBrainsMono .fonts/
    ```

   Now, if you open preferences in Gnome Tweaks, you should be able to select the font you just installed.  
   > Fonts: `JetBrainsMonoNL Nerd Font Mono`  

9. Fetch the dotfiles:

    ```shell
    git clone https://github.com/andrerclaudio/dotfiles.git
    ```

10. Install TPM (Tmux Plugin Manager):

    ```shell
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    ```

    > `After moving the Tmux dotfile to its place inside ~/.config folder, press prefix + I to install the plugins.`

11. Install ZSH pluggins:

    ```shell
    git clone https://github.com/zsh-users/zsh-autosuggestions.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    git clone --depth 1 -- https://github.com/marlonrichert/zsh-autocomplete.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autocomplete
    git clone https://github.com/TamCore/autoupdate-oh-my-zsh-plugins.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/autoupdate
    ```

12. Install MFGTools:

    ```shell
    git clone https://github.com/nxp-imx/mfgtools.git
    cd mfgtools
    git checkout tags/uuu_1.5.182 -b uuu_1.5.182
    cmake -S . -B build
    cmake --build build --target all
    sudo cp ./build/uuu/uuu /bin
    ```

13. Install SetupSTM32CubeProgrammer:

    - Download STM32Cube [https://www.st.com/en/development-tools/stm32cubeprog.html#get-software]
    - Unzip and run ./SetupSTM32CubeProgrammer-2.16.0.linux
    - Add to .zshrc file "export PATH=my_STM32CubeProgrammer_install_directory/bin:$PATH"

    ```shell
    cd <your STM32CubeProgrammer install directory>/Drivers/rules
    sudo cp *.* /etc/udev/rules.d/
    ```

14. Restart the PC:

    ```shell
    sudo reboot
    ```

15. Install PWA appplications:

    - Tldr
    - Google Keep
    - Google Maps
    - Google Photos
    - WhatsApp

16. Install Gnome Extensions:

    - Caffeine
    - Dash to Dock
    - Blur my Shell
    - Logo Menu
    - Clipboard Indicator

17. Install Cargo Apps

    ```shell
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    cargo install tock eza pueue dysk yazi-build ripgrep weathr cargo-update
    ```

18. Install OpenVPN

    > Go to CloudConnexa [https://myaccount.openvpn.com/signin/cvpn/previous-credentials]  
    > Follow the steps to add a new Host.

    ```shell
    sudo systemctl status openvpn3-session@CloudConnexa.service
    ```

19. Install Spicetify

    ```shell
    curl -fsSL https://raw.githubusercontent.com/spicetify/cli/main/install.sh | sh
    ```

    > `DO NOT` install the Marketplace when requested.

    ```shell
    spicetify
    cd .config/spicetify/
    nano config-xpui.ini
    ```

    > Then add:

    ```nano
    prefs_path             = /home/algernon/.var/app/com.spotify.Client/config/spotify/prefs
    ```

    > Then make:

    ```shell
    sudo chmod a+wr /var/lib/flatpak/app/com.spotify.Client/x86_64/stable/active/files/extra/share/spotify
    sudo chmod a+wr -R /var/lib/flatpak/app/com.spotify.Client/x86_64/stable/active/files/extra/share/spotify/Apps
    spicetify backup apply
    spicetify apply
    ```

    > To install the GruvBox extension, do as below:

    ```shell
    cd
    cd .config/spicetify/Themes
    git clone https://github.com/Skaytacium/Gruvify
    cd Gruvify
    sudo npm i -g sass
    sass user.sass user.css
    spicetify config current_theme Gruvify
    spicetify apply
    ```

20. Install Zoxide

    ```shell
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
    ```

21. Install Atuin

    ```shell
    curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
    atuin login -u andrerclaudio
    atuin sync
    ```

22. Configure Eza

    ```shell
    mkdir -p ~/.config/eza
    cd ~/.config/eza
    git clone https://github.com/eza-community/eza-themes.git
    ln -sf "$(pwd)/eza-themes/themes/gruvbox-dark.yml" ~/.config/eza/theme.yml
    ```

23. Setting up `pueue` daemon

    - Download pueued.service from the GitHub Releases page.  
    - Place systemd.pueued.service in /usr/lib/systemd/user  
    - Make sure the pueued binary is placed at /usr/bin/, which is where pueued.service expects it to be.  
    - Then, run:  

    ```shell
    systemctl --user enable --now systemd.pueued
    sudo systemctl daemon-reload
    systemctl --user status systemd.pueued
    ```

24. Change DNS addresses

    > Go to Wifi settings and change DNS from automatic to manual and add.  

    `IPV4`:  
    8.8.8.8,8.8.4.4

    `IPV6`:  
    2001:4860:4860::8888,2001:4860:4860::8844  

25. Tune VsCode settings

    ```shell
    sudo nano /etc/sysctl.conf
    ```

    Add `fs.inotify.max_user_watches=524288` at the end of the file and save it.  
    Run the code below to reload the settings.

    ```shell
    sudo sysctl -p
    ```

26. Gruvbox Plus icon pack  

    ```shell
    cd
    mkdir .icons
    cd Documents
    git clone https://github.com/SylEleuth/gruvbox-plus-icon-pack.git
    ln -s /home/algernon/Documents/gruvbox-plus-icon-pack/Gruvbox-Plus-Dark ~/.icons/Gruvbox-Plus-Dark
    ```  

    Now, if you open preferences in Gnome Tweaks, you should be able to select the icon pack you just installed.  

    > Appearance (Icons): `Gruvbox-Plus-Dark`  

27. Add the Host Macondo (Server)  

    ```shell
    sudo nano /etc/hosts
    ```

    And add the lines below:

    ```shell
    100.96.1.34 macondo personal.server
    ```

28. Install Nvidia drivers if needed

    Go to [**Nvidia CUDA drivers**](https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=x86_64&Distribution=Fedora&target_version=42) and install the Fedora drivers.

    or  

    ```shell
    sudo dnf install akmod-nvidia xorg-x11-drv-nvidia-cuda nvidia-settings nvidia-persistenced nvidia-modprobe
    ```

29. Install Repo tool

    ```shell
    curl http://commondatastorage.googleapis.com/git-repo-downloads/repo  > ~/.local/bin/repo
    chmod a+x ~/.local/bin/repo
    ```
