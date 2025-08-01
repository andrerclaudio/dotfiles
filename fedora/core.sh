#!/bin/bash

# Function to pause the script for a given number of seconds
pause_script() {
    echo "Pausing for $1 seconds..."
    sleep "$1"
}

# Function to remove LibreOffice
remove_libreoffice() {
    echo "# -----------------------------------------------------------------------#"
    echo "# Removing LibreOffice                                                   #"
    echo "# -----------------------------------------------------------------------#"
    sudo dnf remove -y libreoffice*
}

# Function to install Flatpak utility and add Flathub repository
install_flatpak_and_add_flathub() {
    echo "# -----------------------------------------------------------------------#"
    echo "# Adding Flatpak utility, Repository, and Apps                           #"
    echo "# -----------------------------------------------------------------------#"
    sudo dnf install -y flatpak
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
}

# Function to add new settings to improve package management efficiency
configure_package_management() {
    echo "# -----------------------------------------------------------------------#"
    echo "# Add new settings to improve package management efficiency              #"
    echo "# -----------------------------------------------------------------------#"
    sudo sed -i '$a\
#\
# New settings to improve the speed and efficiency of package management operations.\
fastestmirror=True\
max_parallel_downloads=11\
defaultyes=True\
keepcache=True' /etc/dnf/dnf.conf
}

# Function to update and upgrade the system
update_and_upgrade() {
    echo "# -----------------------------------------------------------------------#"
    echo "# Update and Upgrade                                                     #"
    echo "# -----------------------------------------------------------------------#"
    sudo dnf upgrade -y
}

# Function to install Visual Studio Code
install_visual_studio_code() {
    echo "# -----------------------------------------------------------------------#"
    echo "# Install Visual Studio Code                                             #"
    echo "# -----------------------------------------------------------------------#"
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
    sudo dnf update -y
    sudo dnf install -y code
}

# Function to add RPM Fusion repository
add_rpm_fusion_repository() {
    echo "# -----------------------------------------------------------------------#"
    echo "# Adding Fusion repository                                               #"
    echo "# -----------------------------------------------------------------------#"
    sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm 
    sudo dnf install -y https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
    sudo dnf config-manager setopt fedora-cisco-openh264.enabled=1
    sudo dnf5 group install -y core
}

# Function to configure GIT credentials
configure_git_credentials() {
    echo "# -----------------------------------------------------------------------#"
    echo "# GIT Credentials                                                        #"
    echo "# -----------------------------------------------------------------------#"
    git config --global user.name "Andre Ribeiro"
    git config --global user.email "andre.ribeiro.srs@gmail.com"
    echo "Git global variables configured successfully."
}

# Function to add serial permissions
add_serial_permissions() {
    echo "# -----------------------------------------------------------------------#"
    echo "# Adding serial permissions                                              #"
    echo "# -----------------------------------------------------------------------#"
    if ! id -nG "$(id -u -n)" | grep -qw "tty"; then
        sudo usermod -a -G tty "$(id -u -n)"
        echo "TTY group permission granted!"
    else
        echo "User already has 'tty' group permission."
    fi

    if ! id -nG "$(id -u -n)" | grep -qw "dialout"; then
        sudo usermod -a -G dialout "$(id -u -n)"
        echo "Dialout group permission granted!"
    else
        echo "User already has 'dialout' group permission."
    fi
}

# Main script execution
configure_package_management
add_rpm_fusion_repository
update_and_upgrade
pause_script 2

remove_libreoffice
pause_script 2

install_flatpak_and_add_flathub
pause_script 2

install_visual_studio_code
pause_script 2

configure_git_credentials
pause_script 2

add_serial_permissions
pause_script 2

echo "# -----------------------------------------------------------------------#"
echo "# Core installs done.                                                    #"
echo "# -----------------------------------------------------------------------#"
