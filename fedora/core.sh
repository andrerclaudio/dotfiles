#!/bin/bash
#
# Fedora post-install, stage 1 of 3: core system configuration.
#
# RUN ORDER:  core.sh  ->  apps.sh  ->  extra.sh
# extra.sh compiles Rust crates against system libraries that apps.sh installs,
# so running it early will fail. See Fedora-Config-Guide.md.

# -u catches unset variables (typos, empty paths). No -e on purpose: a single
# failed package should not abort the whole run.
set -uo pipefail

LOG_FILE="$HOME/fedora-setup-core.log"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "Logging this run to $LOG_FILE"

# Pre-authenticate sudo, then refresh the timestamp every 50s so long dnf
# transactions don't stall on a password prompt halfway through.
sudo -v
while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done &
SUDO_KEEPALIVE_PID=$!
trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null' EXIT

# Print a section header (same output as before, just less repetition)
banner() {
    echo "# -----------------------------------------------------------------------#"
    printf '# %-71s#\n' "$1"
    echo "# -----------------------------------------------------------------------#"
}

# Function to pause the script for a given number of seconds
pause_script() {
    echo "Pausing for $1 seconds..."
    sleep "$1"
}

# Function to add new settings to improve package management efficiency
configure_package_management() {
    banner "Add new settings to improve package management efficiency"

    # 'config-manager setopt' instead of appending with sed: it is idempotent,
    # so re-running the script won't stack duplicate blocks in dnf.conf.
    # NOTE: defaultyes=True makes a bare Enter mean "yes" on every dnf prompt.
    #       Convenient, but it removes the safety net on 'dnf remove'.
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

    # Bulk removal + autoremove can drag out more than intended. Cheap sanity
    # check so a broken desktop is caught here rather than after the reboot.
    local critical=("gnome-shell" "gdm" "gnome-session" "nautilus")
    local pkg missing=()
    for pkg in "${critical[@]}"; do
        rpm -q "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
    done
    if ((${#missing[@]})); then
        echo "!!! WARNING: these desktop packages are gone: ${missing[*]}"
        echo "!!! Reinstall before rebooting:  sudo dnf install ${missing[*]}"
    else
        echo "---> Desktop packages intact."
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

# Function to install Visual Studio Code
install_visual_studio_code() {
    banner "Install Visual Studio Code"
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo tee /etc/yum.repos.d/vscode.repo >/dev/null <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
    sudo dnf install -y code
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

    # DNF5 dropped '--set-enabled'; config-manager now uses subcommands.
    sudo dnf config-manager setopt fedora-cisco-openh264.enabled=1
    sudo dnf group install -y core
}

# Function to configure GIT credentials
configure_git_credentials() {
    banner "GIT Credentials"
    git config --global user.name "Andre Ribeiro"
    git config --global user.email "andre.ribeiro.srs@gmail.com"
    git config --global init.defaultBranch main
    echo "Git global variables configured successfully."
}

# Function to add serial permissions
add_serial_permissions() {
    banner "Adding serial permissions (tty, dialout)"
    local USER_NAME
    USER_NAME=$(id -u -n)

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

    echo "NOTE: group changes only apply after a full logout or reboot."
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

banner "Core installs done. Reboot, then run ./apps.sh"