#!/bin/bash

# Function to pause the script for a given number of seconds
pause_script() {
    echo "Pausing for $1 seconds..."
    sleep "$1"
}

# Function to add 3-party repositories
add_apps_repo() {
    echo "# -----------------------------------------------------------------------#"
    echo "# Add LazyGit repository                                                 #"
    echo "# -----------------------------------------------------------------------#"
    sudo dnf copr enable -y atim/lazygit
    sudo dnf copr enable -y scottames/ghostty
}

# Function to install packages via DNF package manager
install_dnf_packages() {
    echo "# -----------------------------------------------------------------------#"
    echo "# Install packages via DNF package manager                               #"
    echo "# -----------------------------------------------------------------------#"
    local packages=(
        "google-chrome-stable"
        "alacritty"
        "zsh"
        "fastfetch"
        "python3-pip"
        "gparted"
        "btop"
        "tmux"
        "cmatrix"
        "asciiquarium"
        "rpi-imager"
        "picocom"
        "net-tools"
        "nmap"
        "libusb1-devel.x86_64"
        "bzip2-devel.x86_64"
        "libzstd-devel.x86_64"
        "pkgconf.x86_64"
        "cmake.x86_64"
        "openssl-devel.x86_64"
        "gcc-c++.x86_64"
        "zlib-devel"
        "tinyxml2-devel.x86_64"
        "aria2"
        "iperf3"
        "htop"
        "dnf-plugins-core"
        "papirus-icon-theme"
        "neovim"
        "gnome-tweaks"
        "cbonsai"
        "codespell"
        "zstd"
        "anaconda"
        "tree"
        "lazygit"
        "zig"
        "doxygen"
        "tldr"
        "distrobox"
        "gdisk"
        "openssl"
        "fedora-packager"
        "bmap-tools"
        "gnome-shell-extension-pop-shell"
        "xprop"
        "gdk-pixbuf2-devel"
        "glib2-devel"
        "gobject-introspection-devel"
        "@development-tools"
        "gtk4-devel"
        "libadwaita-devel"
        "python3-devel"
        "pkg-config"
        "gdb"
        "qemu"
        "cairo-devel"
        "cava"
        "powerline-fonts"
        "fontawesome-fonts"
        "fzf"
        "bat"
        "libavcodec-freeworld"
        "pycharm-community"
        "python3-tkinter"
        "ghostty"
        "grc"
        "ffmpeg-free"
        "0ad"
        "luarocks"
    )
    sudo dnf install -y "${packages[@]}"
}

# Main script execution
#
add_apps_repo
pause_script 2

install_dnf_packages
pause_script 2

echo "# -----------------------------------------------------------------------#"
echo "# All tasks completed.                                                   #"
echo "# -----------------------------------------------------------------------#"
