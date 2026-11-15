#!/bin/bash
# Fedora post-install, stage 1 of 4: core system.

# No -e: one failed step should not abort the run.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# shellcheck source=SCRIPTDIR/lib.sh
source "$SCRIPT_DIR/lib.sh"

GIT_USER_NAME="Andre Ribeiro"
GIT_USER_EMAIL="andre.ribeiro.srs@gmail.com"

init_stage "$HOME/fedora-setup-core.log"

# Tools the later steps need.
ensure_dnf_prereqs() {
    banner "Installing prerequisites (dnf5-plugins, git)"
    sudo dnf install -y dnf5-plugins git
}

configure_package_management() {
    banner "Setting DNF options"

    # More than ~7 parallel downloads make mirrors time out.
    sudo dnf config-manager setopt \
        fastestmirror=True \
        max_parallel_downloads=7 \
        defaultyes=True
}

update_and_upgrade() {
    banner "Updating the system"
    sudo dnf upgrade -y
}

remove_unwanted_defaults() {
    banner "Removing unwanted default apps"

    # Globs match a whole suite.
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
        "gnome-extensions-app"
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

    echo "---> Removing the packages and unused dependencies..."
    sudo dnf remove -y "${apps[@]}"
    sudo dnf autoremove -y
}

install_flatpak_and_add_flathub() {
    banner "Installing Flatpak and adding Flathub"
    sudo dnf install -y flatpak

    # Per-user remote, as apps.sh installs with --user.
    flatpak remote-add --user --if-not-exists flathub \
        https://dl.flathub.org/repo/flathub.flatpakrepo
}

install_snapd() {
    banner "Installing snapd"
    sudo dnf install -y snapd

    # /snap is where classic snaps expect to find themselves.
    [[ -e /snap ]] || sudo ln -s /var/lib/snapd/snap /snap
}

add_rpm_fusion_repository() {
    banner "Adding the RPM Fusion repositories"
    local fedora_ver
    fedora_ver=$(rpm -E %fedora)

    # Check the release RPMs against RPM Fusion's keys.
    local keys=/usr/share/distribution-gpg-keys/rpmfusion
    sudo dnf install -y distribution-gpg-keys
    sudo rpmkeys --import \
        "$keys/RPM-GPG-KEY-rpmfusion-free-fedora-${fedora_ver}" \
        "$keys/RPM-GPG-KEY-rpmfusion-nonfree-fedora-${fedora_ver}"
    sudo dnf install -y --setopt=localpkg_gpgcheck=1 \
        "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${fedora_ver}.noarch.rpm" \
        "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${fedora_ver}.noarch.rpm"

    # Stop here: without RPM Fusion, apps.sh would skip the codecs.
    if ! rpm -q rpmfusion-free-release rpmfusion-nonfree-release >/dev/null 2>&1; then
        echo "!!! RPM Fusion is missing. Run ./core.sh again before ./apps.sh."
        exit 1
    fi
}

tune_inotify_limit() {
    banner "Raising the inotify watch limit (VS Code, Syncthing)"

    # A drop-in, kept apart from /etc/sysctl.conf.
    echo "fs.inotify.max_user_watches=524288" \
        | sudo tee /etc/sysctl.d/99-inotify.conf >/dev/null

    # Load only this drop-in.
    echo "---> Applying the new limit..."
    sudo sysctl -q -p /etc/sysctl.d/99-inotify.conf
    sysctl fs.inotify.max_user_watches
}

create_swap_file() {
    banner "Creating the swap file"

    # Runs as the user (it calls sudo itself); skips if /swapfile exists.
    bash "$REPO_ROOT/tools/change_swap.sh" \
        || echo "!!! Swap file setup failed; see $LOG_FILE."
}

configure_git_credentials() {
    banner "Configuring git"

    # Global settings, so warn before replacing an existing value.
    local key old
    for key in user.name user.email; do
        old=$(git config --global --get "$key")
        [[ -n "$old" ]] && echo "NOTE: overwriting existing global git $key ('$old')."
    done

    git config --global user.name "$GIT_USER_NAME"
    git config --global user.email "$GIT_USER_EMAIL"
    git config --global init.defaultBranch main
    echo "---> Git configured."
}

generate_solid_wallpapers() {
    banner "Writing the solid Gruvbox wallpapers"

    # Pillow draws the PNGs.
    sudo dnf install -y python3-pillow

    # Show only the summary line.
    python3 "$REPO_ROOT/tools/colors_solid.py" | tail -n 1 \
        || echo "!!! Wallpaper generation failed; see $LOG_FILE."
}

add_serial_permissions() {
    banner "Adding serial permissions (dialout)"
    # dialout covers ttyUSB*, ttyACM* and ttyS*.
    local user_name
    user_name=$(id -u -n)

    if id -nG "$user_name" | grep -qw dialout; then
        echo "---> Already in dialout."
    else
        sudo usermod -a -G dialout "$user_name"
        echo "---> Added to dialout."
    fi

    echo "NOTE: group changes need a full logout or reboot."
}

ensure_dnf_prereqs
configure_package_management
add_rpm_fusion_repository
remove_unwanted_defaults
update_and_upgrade
install_flatpak_and_add_flathub
install_snapd
tune_inotify_limit
create_swap_file
configure_git_credentials
generate_solid_wallpapers
add_serial_permissions

banner "Core setup done. Reboot, then run ./apps.sh"
