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
    sudo mv ./JetBrainsMono /usr/share/fonts/JetBrainsMono
    cd /usr/share/fonts/
    sudo fc-cache -f -v
    ```

   Now, if you open preferences in Gnome Tweaks, you should be able to select the font you just installed.  
   > Fonts: `JetBrainsMonoNL Nerd Font Mono`  
   > Appearance (Icons): `Papirus`  

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
    sudo git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    sudo git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
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

    - Google Drive
    - Github
    - Tldr
    - Google Keep
    - Google Photos
    - Youtube
    - WhatsApp

16. Install Gnome Extensions:

    - Caffeine
    - Just Perfection
    - Transparent Top Bar

17. Install Cargo Apps

    ```shell
    cargo install tock
    cargo install --locked yazi-fm yazi-cli
    ```

18. Install OpenVPN

    > Go to CloudConnexa [https://myaccount.openvpn.com/signin/cvpn/previous-credentials]  
    > Follow the steps to add a new Host.  
    > After installing it, remember to disable the client isntance and avoid it to start at boot time yo avoit clonflicting with TwinGate connector client.

    ```shell
    sudo systemctl status openvpn3-session@CloudConnexa.service
    sudo systemctl stop openvpn3-session@CloudConnexa.service
    sudo systemctl disable openvpn3-session@CloudConnexa.service
    sudo systemctl daemon-reload
    ```

19. Install TwinGate client

    ```shell
    sudo dnf install -y 'dnf-command(config-manager)'
    sudo dnf config-manager addrepo --set=baseurl="https://packages.twingate.com/rpm/"
    sudo dnf config-manager setopt "packages.twingate.com_rpm_.gpgcheck=0"
    sudo dnf install -y "twingate"
    sudo twingate setup
    ```

20. Install ZED editor

    ```shell
    curl -f https://zed.dev/install.sh | sh
    ```

21. Install Ananicy-Cpp

    ```shell
    cd Downloads
    git clone https://gitlab.com/ananicy-cpp/ananicy-cpp.git
    cd ananicy-cpp
    cmake -B build -S .
    cmake --build build --target ananicy-cpp
    sudo cmake --install build --component Runtime
    ```

    > Clone the CachyOs rules before starting the Ananicy.

    ```shell
    cd Downloads
    https://github.com/CachyOS/ananicy-rules.git
    cd /etc/ananicy.d
    sudo rm -rf ./*
    sudo cp -r /home/algernon/Downloads/ananicy-rules/* .
    ```

    > Then, make it a service:

    ```shell
    sudo systemctl enable --now ananicy-cpp.service
    sudo systemctl start ananicy-cpp.service
    ```

22. Install Spicetify

    ```shell
    curl -fsSL https://raw.githubusercontent.com/spicetify/cli/main/install.sh | sh
    ```

    > `DO NOT` install the Marketplace when requested.

    Enter with `spicetify apply` in the terminal so it will genrenate the config file.

    ```shell
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

    > To install the GruvBox exntensio, do as below:

    ```shell
    git clone --depth=1 https://github.com/spicetify/spicetify-themes.git 
    cd spicetify-themes
    cp -r * ~/.config/spicetify/Themes
    spicetify config current_theme text color_scheme Gruvbox
    spicetify config inject_css 1 replace_colors 1 overwrite_assets 1 inject_theme_js 1
    spicetify apply
