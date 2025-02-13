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
}

# Function to install packages via DNF package manager
install_dnf_packages() {
    echo "# -----------------------------------------------------------------------#"
    echo "# Install packages via DNF package manager                               #"
    echo "# -----------------------------------------------------------------------#"
    local packages=(
        "alacritty"
        "zsh"
        "fastfetch"
        "python3-pip"
        "gparted"
        "btop"
        "tmux"
        "cmatrix"
        "bat"
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
        "zoxide"
        "htop"
        "dnf-plugins-core"
        "papirus-icon-theme"
        "neovim"
        "gnome-tweaks"
        "cbonsai"
        "codespell"
        "zstd"
        "anaconda"
        "git-email"
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
        "libcairo2-dev"
        "pkg-config"
        "0ad"
        "eza"
        "gdb"
    )
    sudo dnf install -y "${packages[@]}"
}

# Function to install Docker
install_docker() {
    echo "# -----------------------------------------------------------------------#"
    echo "# Installing Docker                                                      #"
    echo "# -----------------------------------------------------------------------#"    
    sudo dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
    sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo groupadd docker
    sudo usermod -aG docker $USER
    sudo systemctl enable docker
}

# Main script execution
#
add_apps_repo
pause_script 2

install_dnf_packages
pause_script 2

install_docker
pause_script 2

echo "# -----------------------------------------------------------------------#"
echo "# All tasks completed.                                                   #"
echo "# -----------------------------------------------------------------------#"
