#!/bin/bash

# Pre-authenticate sudo so the script doesn't stall later
sudo -v

# Function to pause the script for a given number of seconds
pause_script() {
    echo "Pausing for $1 seconds..."
    sleep "$1"
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
max_parallel_downloads=19\
defaultyes=True\
keepcache=True' /etc/dnf/dnf.conf
}

# Function to update and upgrade the system
update_and_upgrade() {
    echo "# -----------------------------------------------------------------------#"
    echo "# System Update and Upgrade                                              #"
    echo "# -----------------------------------------------------------------------#"
    sudo dnf upgrade -y
}

# Function to remove unwanted defaults (GNOME Apps & LibreOffice)
remove_unwanted_defaults() {
    echo "# -----------------------------------------------------------------------#"
    echo "# Removing Unwanted Defaults (GNOME Apps & LibreOffice)                  #"
    echo "# -----------------------------------------------------------------------#"

    # Combined and alphabetized list, including libreoffice*
    local apps=(
        "baobab"
        "decibels"
        "firefox"
        "gnome-boxes"
        "gnome-calculator"
        "gnome-calendar"
        "gnome-characters"
        "gnome-clocks"
        "gnome-connections"
        "gnome-contacts"
        "gnome-font-viewer"
        "gnome-logs"
        "gnome-maps"
        "gnome-text-editor"
        "gnome-weather"
        "libreoffice*"
        "loupe"
        "mediawriter"
        "papers"
        "showtime"
        "simple-scan"
        "snapshot"
    )

    echo "---> Removing selected packages and unused dependencies..."
    sudo dnf remove -y "${apps[@]}"
    sudo dnf autoremove -y
    echo "---> Cleanup complete."
}

# Function to install Flatpak utility and add Flathub repository
install_flatpak_and_add_flathub() {
    echo "# -----------------------------------------------------------------------#"
    echo "# Adding Flatpak utility and Flathub Repository                          #"
    echo "# -----------------------------------------------------------------------#"
    sudo dnf install -y flatpak
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
}

# Function to install Visual Studio Code
install_visual_studio_code() {
    echo "# -----------------------------------------------------------------------#"
    echo "# Install Visual Studio Code                                             #"
    echo "# -----------------------------------------------------------------------#"
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
    sudo dnf install -y code
}

# Function to add RPM Fusion repository
add_rpm_fusion_repository() {
    echo "# -----------------------------------------------------------------------#"
    echo "# Adding RPM Fusion repository                                           #"
    echo "# -----------------------------------------------------------------------#"
    sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm 
    sudo dnf install -y https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
    sudo dnf config-manager --set-enabled fedora-cisco-openh264
    sudo dnf group install -y core
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
    echo "# Adding serial permissions (tty, dialout)                               #"
    echo "# -----------------------------------------------------------------------#"
    local USER_NAME=$(id -u -n)

    if ! id -nG "$USER_NAME" | grep -qw "tty"; then
        sudo usermod -a -G tty "$USER_NAME"
        echo "TTY group permission granted!"
    else
        echo "User already has 'tty' group permission."
    fi

    if ! id -nG "$USER_NAME" | grep -qw "dialout"; then
        sudo usermod -a -G dialout "$USER_NAME"
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

remove_unwanted_defaults
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
