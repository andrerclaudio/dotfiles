#!/bin/bash

# Pre-authenticate sudo so the script doesn't stall waiting for a password later
sudo -v

# Function to pause the script for a given number of seconds
pause_script() {
    echo "Pausing for $1 seconds..."
    sleep "$1"
}

# Function to add 3rd-party repositories
add_apps_repo() {
    echo "# -----------------------------------------------------------------------#"
    echo "# Add 3rd-Party Repositories (LazyGit, Ghostty, Yazi)                    #"
    echo "# -----------------------------------------------------------------------#"
    sudo dnf copr enable -y atim/lazygit
    sudo dnf copr enable -y scottames/ghostty
    sudo dnf copr enable -y lihaohong/yazi
    
    # Refresh cache to ensure new repos are immediately available
    sudo dnf makecache
}

# Function to install a list of Flatpak apps
install_flatpak_apps() {
    echo "# -----------------------------------------------------------------------#"
    echo "# Install packages via Flatpak                                           #"
    echo "# -----------------------------------------------------------------------#"

    # Alphabetized list for easier maintenance
    local apps=(
        "com.mattjakeman.ExtensionManager"
        "com.ranfdev.DistroShelf"
        "de.haeckerfelix.Fragments"
        "io.github.flattool.Warehouse"
        "org.fedoraproject.MediaWriter"
        "org.filezillaproject.Filezilla"
        "org.gimp.GIMP"
        "org.gnome.Boxes"
        "org.gnome.Calendar"
        "org.gnome.Calculator"
        "org.gnome.Characters"
        "org.gnome.Connections"
        "org.gnome.Evince"
        "org.gnome.GHex"
        "org.gnome.Logs"
        "org.gnome.Loupe"
        "org.gnome.TextEditor"
        "org.gnome.baobab"
        "org.gnome.clocks"
        "org.gnome.font-viewer"
        "org.gnome.meld"
        "org.inkscape.Inkscape"
        "org.kde.kdenlive"
        "org.libreoffice.LibreOffice"
        "org.nickvision.tubeconverter"
        "org.octave.Octave"
        "org.remmina.Remmina"
        "org.videolan.VLC"
    )

    # Batch install strictly for the current user
    echo "---> Installing Flathub applications..."
    flatpak install --user flathub "${apps[@]}" -y
}

# Function to install apps via DNF package manager
install_dnf_packages() {
    echo "# -----------------------------------------------------------------------#"
    echo "# Install packages via DNF package manager                               #"
    echo "# -----------------------------------------------------------------------#"
    
    # Alphabetized list for easier maintenance
    local packages=(
        "0ad"
        "@development-tools"
        "alacritty"
        "aria2"
        "asciiquarium"
        "bat"
        "bmap-tools"
        "btop"
        "bzip2-devel.x86_64"
        "cairo-devel"
        "cava"
        "cbonsai"
        "chafa"
        "cmake.x86_64"
        "cmatrix"
        "codespell"
        "distrobox"
        "dnf-plugins-core"
        "doxygen"
        "fastfetch"
        "fedora-packager"
        "ffmpeg-free"
        "fontawesome-fonts"
        "fzf"
        "gcc-c++.x86_64"
        "gdb"
        "gdisk"
        "gdk-pixbuf2-devel"
        "ghostty"
        "glib2-devel"
        "gnome-shell-extension-pop-shell"
        "gnome-tweaks"
        "gobject-introspection-devel"
        "google-chrome-stable"
        "gparted"
        "grc"
        "gtk4-devel"
        "htop"
        "iperf3"
        "lazygit"
        "libadwaita-devel"
        "libavcodec-freeworld"
        "libusb1-devel.x86_64"
        "libzstd-devel.x86_64"
        "luarocks"
        "mpv"
        "neovim"
        "net-tools"
        "nmap"
        "openssl"
        "openssl-devel.x86_64"
        "papirus-icon-theme"
        "picocom"
        "pkg-config"
        "pkgconf.x86_64"
        "podman-compose"
        "powerline-fonts"
        "pycharm-community"
        "python3-devel"
        "python3-pip"
        "python3-tkinter"
        "qemu"
        "rpi-imager"
        "tio"
        "tinyxml2-devel.x86_64"
        "tldr"
        "tmux"
        "tree"
        "xprop"
        "yazi"
        "zig"
        "zlib-devel"
        "zstd"
        "zsh"
    )
    sudo dnf install -y --skip-unavailable "${packages[@]}"
}

# Main script execution
install_flatpak_apps
pause_script 2

add_apps_repo
pause_script 2

install_dnf_packages
pause_script 2

echo "# -----------------------------------------------------------------------#"
echo "# Application installation complete.                                     #"
echo "# -----------------------------------------------------------------------#"