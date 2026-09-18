#!/bin/bash
#
# Fedora post-install, stage 1 of 3: core system configuration.
#
# RUN ORDER:  core.sh  ->  apps.sh  ->  extra.sh

# -u catches unset variables. No -e: one failed package should not abort the run.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

GIT_USER_NAME="Andre Ribeiro"
GIT_USER_EMAIL="andre.ribeiro.srs@gmail.com"

init_stage "$HOME/fedora-setup-core.log"

# Without dnf5-plugins every setopt and copr call is a silent no-op. git is
# needed by configure_git_credentials.
ensure_dnf_prereqs() {
    banner "Ensuring prerequisites (dnf5-plugins, git)"
    sudo dnf install -y dnf5-plugins git
}

configure_package_management() {
    banner "Add new settings to improve package management efficiency"

    # Above ~7 the streams starve each other and dnf times mirrors out.
    sudo dnf config-manager setopt \
        fastestmirror=True \
        max_parallel_downloads=7 \
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

    # dnf5 aborts on any argument that matches nothing installed, so pass only
    # what is here. 'rpm -qa' expands globs; 'rpm -q' does not.
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

    # apps.sh installs everything with --user, and --user keeps its own remotes.
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
    banner "Adding RPM Fusion repository"
    local fedora_ver
    fedora_ver=$(rpm -E %fedora)

    sudo dnf install -y \
        "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${fedora_ver}.noarch.rpm" \
        "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${fedora_ver}.noarch.rpm"

    # The mirror handed out is random and some are down, so this can fail for no
    # good reason. Stop rather than let apps.sh silently drop the codecs;
    # re-running core.sh is safe.
    if ! rpm -q rpmfusion-free-release rpmfusion-nonfree-release >/dev/null 2>&1; then
        echo "!!! RPM Fusion is missing - codecs would be skipped by apps.sh."
        echo "!!! Check the network and re-run ./core.sh before apps.sh."
        exit 1
    fi
}

tune_inotify_limit() {
    banner "Raising the inotify watch limit (VS Code, syncthing)"

    # A drop-in, not /etc/sysctl.conf: that file is deprecated and gets replaced
    # on some upgrades.
    echo "fs.inotify.max_user_watches=524288" \
        | sudo tee /etc/sysctl.d/99-inotify.conf >/dev/null

    # -p on the one file, not --system: --system reprints every drop-in on the box.
    echo "---> Applying the new limit..."
    sudo sysctl -q -p /etc/sysctl.d/99-inotify.conf
    sysctl fs.inotify.max_user_watches
}

configure_git_credentials() {
    banner "GIT Credentials"

    # Global settings, so warn before replacing an existing value.
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

ensure_dnf_prereqs
configure_package_management
add_rpm_fusion_repository
update_and_upgrade
remove_unwanted_defaults
install_flatpak_and_add_flathub
install_snapd
tune_inotify_limit
configure_git_credentials
add_serial_permissions

banner "Core installs done. Reboot, then run ./apps.sh"
