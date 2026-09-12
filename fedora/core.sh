#!/bin/bash
#
# Fedora post-install, stage 1 of 3: core system configuration.
#
# RUN ORDER:  core.sh  ->  apps.sh  ->  extra.sh

# -u catches unset variables. No -e: one failed package should not abort the run.
set -uo pipefail

# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

GIT_USER_NAME="Andre Ribeiro"
GIT_USER_EMAIL="andre.ribeiro.srs@gmail.com"

init_stage "$HOME/fedora-setup-core.log"

# Without dnf5-plugins every setopt and copr call below is a silent no-op.
ensure_dnf_plugins() {
    banner "Ensuring dnf5-plugins (provides config-manager, copr)"
    sudo dnf install -y dnf5-plugins
}

configure_package_management() {
    banner "Add new settings to improve package management efficiency"

    sudo dnf config-manager setopt \
        fastestmirror=True \
        max_parallel_downloads=19 \
        defaultyes=True \
        keepcache=True
}

update_and_upgrade() {
    banner "System Update and Upgrade"
    sudo dnf upgrade -y
}

remove_unwanted_defaults() {
    banner "Removing Unwanted Defaults (GNOME Apps & LibreOffice)"

    # libreoffice* matches the whole suite.
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

    # dnf5 aborts the whole transaction on any argument that matches nothing
    # installed, so pass only what is here. 'rpm -qa' expands globs; 'rpm -q' does not.
    local pkg installed=()
    for pkg in "${apps[@]}"; do
        [[ -n "$(rpm -qa "$pkg" 2>/dev/null)" ]] && installed+=("$pkg")
    done

    echo "---> Removing selected packages and unused dependencies..."
    if ((${#installed[@]})); then
        sudo dnf remove -y "${installed[@]}"
        sudo dnf autoremove -y
    fi

    echo "---> Cleanup complete."
}

install_flatpak_and_add_flathub() {
    banner "Adding Flatpak utility and Flathub Repository"
    sudo dnf install -y flatpak

    # User and system installs keep separate remote lists, and apps.sh installs
    # everything with --user.
    flatpak remote-add --user --if-not-exists flathub \
        https://dl.flathub.org/repo/flathub.flatpakrepo
}

add_rpm_fusion_repository() {
    banner "Adding RPM Fusion repository"
    local fedora_ver
    fedora_ver=$(rpm -E %fedora)

    sudo dnf install -y \
        "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${fedora_ver}.noarch.rpm"
    sudo dnf install -y \
        "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${fedora_ver}.noarch.rpm"

    sudo dnf config-manager setopt fedora-cisco-openh264.enabled=1
    sudo dnf group install -y core
}

configure_git_credentials() {
    banner "GIT Credentials"

    # These are global settings shared by every repo on the machine, so say so
    # when an earlier value is about to be replaced by the one at the top here.
    local key old
    for key in user.name user.email; do
        old=$(git config --global --get "$key")
        [[ -n "$old" ]] && echo "NOTE: overwriting existing global git $key ('$old')."
    done

    git config --global user.name "$GIT_USER_NAME"
    git config --global user.email "$GIT_USER_EMAIL"
    git config --global init.defaultBranch main
    echo "Git global variables configured successfully."
}

add_serial_permissions() {
    banner "Adding serial permissions (tty, dialout)"
    local user_name group
    user_name=$(id -u -n)

    for group in tty dialout; do
        if id -nG "$user_name" | grep -qw "$group"; then
            echo "User already has '$group' group permission."
        else
            sudo usermod -a -G "$group" "$user_name"
            echo "${group^} group permission granted!"
        fi
    done

    echo "NOTE: group changes only apply after a full logout or reboot."
}

ensure_dnf_plugins
configure_package_management
add_rpm_fusion_repository
update_and_upgrade
remove_unwanted_defaults
install_flatpak_and_add_flathub
configure_git_credentials
add_serial_permissions

banner "Core installs done. Reboot, then run ./apps.sh"
