#!/bin/bash
#
# Fedora post-install, stage 1 of 3: core system configuration.
#
# RUN ORDER:  core.sh  ->  apps.sh  ->  extra.sh
# extra.sh compiles Rust crates against a toolchain and libraries that apps.sh
# installs, so running it early will fail.
#
#

# -u catches unset variables (typos, empty paths). No -e on purpose: a single
# failed package should not abort the whole run.
set -uo pipefail

GIT_USER_NAME="Andre Ribeiro"
GIT_USER_EMAIL="andre.ribeiro.srs@gmail.com"

LOG_FILE="$HOME/fedora-setup-core.log"

((EUID)) || { echo "Run this as your normal user, not with sudo."; exit 1; }

exec > >(tee -a "$LOG_FILE") 2>&1
echo "Logging this run to $LOG_FILE"

# Pre-authenticate sudo and keep the timestamp alive for the whole run. Output to
# /dev/null so the job cannot hold the log pipe open after the script exits.
sudo -v || exit 1
{ while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done; } >/dev/null 2>&1 &
SUDO_KEEPALIVE_PID=$!
trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null' EXIT

# Print a section header
banner() {
    echo "# -----------------------------------------------------------------------#"
    printf '# %-71s#\n' "$1"
    echo "# -----------------------------------------------------------------------#"
}

# config-manager and copr are not built into dnf5; they come from dnf5-plugins.
# Without it every setopt and copr call below is a silent no-op.
ensure_dnf_plugins() {
    banner "Ensuring dnf5-plugins (provides config-manager, copr)"
    sudo dnf install -y dnf5-plugins
}

# Function to add new settings to improve package management efficiency
configure_package_management() {
    banner "Add new settings to improve package management efficiency"

    # 'setopt' is idempotent, so re-running this script leaves dnf.conf with one
    # copy of each setting.
    sudo dnf config-manager setopt \
        fastestmirror=True \
        max_parallel_downloads=19 \
        defaultyes=True \
        keepcache=True
}

# Function to update and upgrade the system
update_and_upgrade() {
    banner "System Update and Upgrade"
    sudo dnf upgrade -y
}

# Function to remove unwanted defaults (GNOME Apps & LibreOffice)
remove_unwanted_defaults() {
    banner "Removing Unwanted Defaults (GNOME Apps & LibreOffice)"

    # Alphabetized; libreoffice* matches the whole suite
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

    # dnf5 aborts the whole transaction when any argument matches nothing
    # installed, so only pass it what is actually here - not every name above
    # ships on every spin (mediawriter is not a Workstation default). 'rpm -qa'
    # rather than 'rpm -q' because it expands globs such as libreoffice*.
    local pkg installed=()
    for pkg in "${apps[@]}"; do
        [[ -n "$(rpm -qa "$pkg" 2>/dev/null)" ]] && installed+=("$pkg")
    done

    echo "---> Removing selected packages and unused dependencies..."
    if ((${#installed[@]})); then
        sudo dnf remove -y "${installed[@]}"
        sudo dnf autoremove -y
    fi

    # Bulk removal plus autoremove can drag out more than intended, and the last
    # line of this script tells you to reboot. Rebooting without gdm or
    # gnome-shell means no graphical session at all, so this one is a hard stop.
    local critical=("gnome-shell" "gdm" "gnome-session" "nautilus") missing=()
    for pkg in "${critical[@]}"; do
        rpm -q "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
    done
    if ((${#missing[@]})); then
        echo "!!! DO NOT REBOOT. These desktop packages are gone: ${missing[*]}"
        echo "!!! Reinstall them first:  sudo dnf install ${missing[*]}"
        exit 1
    fi

    echo "---> Cleanup complete."
}

# Function to install Flatpak utility and add Flathub repository
install_flatpak_and_add_flathub() {
    banner "Adding Flatpak utility and Flathub Repository"
    sudo dnf install -y flatpak

    # --user is required here: user and system installations keep separate
    # remote lists, and apps.sh installs everything with --user.
    flatpak remote-add --user --if-not-exists flathub \
        https://dl.flathub.org/repo/flathub.flatpakrepo
}

# Function to add RPM Fusion repository
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

# Function to configure GIT credentials
configure_git_credentials() {
    banner "GIT Credentials"
    git config --global user.name "$GIT_USER_NAME"
    git config --global user.email "$GIT_USER_EMAIL"
    git config --global init.defaultBranch main
    echo "Git global variables configured successfully."
}

# Function to add serial permissions
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

# Main script execution
ensure_dnf_plugins
configure_package_management
add_rpm_fusion_repository
update_and_upgrade
remove_unwanted_defaults
install_flatpak_and_add_flathub
configure_git_credentials
add_serial_permissions

banner "Core installs done. Reboot, then run ./apps.sh"
