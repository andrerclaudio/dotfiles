#!/bin/bash
#
# Fedora post-install, stage 2 of 3: applications.
#
# RUN ORDER:  core.sh  ->  apps.sh  ->  extra.sh
# Must run before extra.sh: the -devel packages here are what the Rust crates
# in extra.sh compile against (alsa-lib-devel, openssl-devel, dbus-devel).

set -uo pipefail

LOG_FILE="$HOME/fedora-setup-apps.log"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "Logging this run to $LOG_FILE"

# Pre-authenticate sudo and keep the timestamp alive for the whole run
sudo -v
while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done &
SUDO_KEEPALIVE_PID=$!
trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null' EXIT

# Print a section header
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

# Function to add 3rd-party repositories
add_apps_repo() {
    banner "Add 3rd-Party Repositories (LazyGit, Ghostty, Yazi, Chrome)"

    sudo dnf copr enable -y atim/lazygit
    sudo dnf copr enable -y scottames/ghostty
    sudo dnf copr enable -y lihaohong/yazi

    # google-chrome-stable lives in a repo that Fedora ships disabled. Without
    # this, --skip-unavailable silently drops Chrome from the install.
    sudo dnf install -y fedora-workstation-repositories
    sudo dnf config-manager setopt google-chrome.enabled=1

    # Refresh cache to ensure new repos are immediately available
    sudo dnf makecache
}

# Function to install apps via DNF package manager
install_dnf_packages() {
    banner "Install packages via DNF package manager"

    # Groups are installed separately so a bad group name is reported clearly
    sudo dnf group install -y development-tools

    # Alphabetized list for easier maintenance.
    # Arch suffixes (.x86_64) dropped: they add noise and pin the list to one
    # architecture for no benefit on a single-arch desktop.
    local packages=(
        "0ad"
        "alacritty"
        "alsa-lib-devel"
        "aria2"
        "asciiquarium"
        "bat"
        "bmap-tools"
        "btop"
        "bzip2-devel"
        "cairo-devel"
        "cava"
        "cbonsai"
        "chafa"
        "cmake"
        "cmatrix"
        "codespell"
        "dbus-devel"
        "distrobox"
        "doxygen"
        "dust"
        "eza"
        "expect"
        "fastfetch"
        "fd-find"
        "fedora-packager"
        "ffmpeg-free"
        "fontawesome-fonts"
        "fzf"
        "gcc-c++"
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
        "libusb1-devel"
        "libzstd-devel"
        "luarocks"
        "mpv"
        "ncdu"
        "neovim"
        "net-tools"
        "nmap"
        "nodejs-npm"
        "openssl"
        "openssl-devel"
        "papirus-icon-theme"
        "picocom"
        "pkgconf-pkg-config"
        "podman-compose"
        "powerline-fonts"
        "pycharm-community"
        "python3-devel"
        "python3-pip"
        "python3-tkinter"
        "qemu"
        "ripgrep"
        "rpi-imager"
        "tinyxml2-devel"
        "tio"
        "tldr"
        "tmux"
        "tree"
        "vim-common"
        "xprop"
        "yazi"
        "zig"
        "zlib-devel"
        "zoxide"
        "zsh"
        "zstd"
    )

    local dnf_log="/tmp/dnf-install-$$.log"
    sudo dnf install -y --skip-unavailable "${packages[@]}" 2>&1 | tee "$dnf_log"

    # --skip-unavailable is convenient but silent. Surface what it dropped so a
    # renamed or retired package doesn't go unnoticed for months.
    echo
    echo "---> Packages DNF could not find (check these by hand):"
    grep -iE "no match for argument|skipping unavailable|not available" "$dnf_log" \
        || echo "     (none - everything resolved)"
    rm -f "$dnf_log"
}

# Function to install a list of Flatpak apps
install_flatpak_apps() {
    banner "Install packages via Flatpak"

    # Alphabetized list for easier maintenance
    local apps=(
        "com.mattjakeman.ExtensionManager"
        "com.ranfdev.DistroShelf"
        "com.spotify.Client"
        "de.haeckerfelix.Fragments"
        "io.github.flattool.Warehouse"
        "org.fedoraproject.MediaWriter"
        "org.filezillaproject.Filezilla"
        "org.gimp.GIMP"
        "org.gnome.Boxes"
        "org.gnome.Calculator"
        "org.gnome.Calendar"
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
        "md.obsidian.Obsidian"
        "com.obsproject.Studio"
        "org.blender.Blender"
        "com.heroicgameslauncher.hgl"
    )

    # The flathub remote must exist in the --user installation (core.sh adds it
    # with --user); re-added here so this script stands on its own.
    flatpak remote-add --user --if-not-exists flathub \
        https://dl.flathub.org/repo/flathub.flatpakrepo

    # Batch install strictly for the current user
    echo "---> Installing Flathub applications..."
    unbuffer flatpak install --user flathub "${apps[@]}" -y
}

# Main script execution
# Repos first: the COPR packages below (ghostty, lazygit, yazi) and Chrome are
# unavailable until this runs, and failures surface early rather than as
# silently skipped packages.
add_apps_repo
pause_script 2

install_dnf_packages
pause_script 2

install_flatpak_apps
pause_script 2

banner "Application installation complete. Reboot, then continue the guide."