#!/bin/bash
#
# RUN ORDER:  core.sh  ->  apps.sh  ->  extra.sh
# Must run before extra.sh: the C toolchain (development-tools) and the -devel
# packages here are what the Rust crates in extra.sh compile against.
#
#

# -u catches unset variables (typos, empty paths). No -e on purpose: a single
# failed package should not abort the whole run.
set -uo pipefail

LOG_FILE="$HOME/fedora-setup-apps.log"

# Under sudo, every --user flatpak below would go into root's installation.
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

# Function to add 3rd-party repositories
add_apps_repo() {
    banner "Add 3rd-Party Repositories (LazyGit, Ghostty, Yazi, Chrome)"

    # None of lazygit, ghostty or yazi is in the official Fedora repos, so these
    # three COPRs are what provides them.
    sudo dnf copr enable -y dejan/lazygit
    sudo dnf copr enable -y scottames/ghostty
    sudo dnf copr enable -y lihaohong/yazi

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
    # Plain names, no .x86_64 suffixes: they add noise and pin the list to one
    # architecture for no benefit.
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
        "du-dust"                  # the binary is 'dust'; the package is du-dust
        "expect"
        "eza"
        "fastfetch"
        "fd-find"
        "fedora-packager"
        "ffmpeg-free"
        "flac-devel"
        "fontawesome-fonts-all"
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
        "libvorbis-devel"
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

    local dnf_log
    dnf_log=$(mktemp -t dnf-install.XXXXXX)

    # --skip-unavailable tolerates names no repo carries; --skip-broken tolerates
    # a package that exists but cannot be solved. Without the second one, a
    # single unsatisfiable dependency aborts the whole transaction.
    sudo dnf install -y --skip-unavailable --skip-broken "${packages[@]}" 2>&1 | tee "$dnf_log" \
        || echo "!!! dnf install failed - NOTHING may have been installed. See $LOG_FILE."

    # Both skip flags are silent about what they drop. Print it, so a package
    # that gets renamed or retired upstream does not go unnoticed for months.
    echo
    echo "---> Packages DNF could not find or resolve (check these by hand):"
    grep -iE "no match for argument|skipping unavailable|not available|broken dependencies" "$dnf_log" \
        || echo "     (none - everything resolved)"
    rm -f "$dnf_log"
}

# Function to install a list of Flatpak apps
install_flatpak_apps() {
    banner "Install packages via Flatpak"

    # Alphabetized list for easier maintenance
    local apps=(
        "app.zen_browser.zen"
        "com.heroicgameslauncher.hgl"
        "com.mattjakeman.ExtensionManager"
        "com.obsproject.Studio"
        "com.ranfdev.DistroShelf"
        "de.haeckerfelix.Fragments"
        "io.github.flattool.Warehouse"
        "md.obsidian.Obsidian"
        "org.blender.Blender"
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
    )

    # One batch first because it is much faster. flatpak refuses the entire batch
    # if a single ID is wrong or renamed, so fall back to one at a time rather
    # than losing all 34 apps to one bad entry.
    echo "---> Installing Flathub applications..."
    flatpak install -y --noninteractive --user flathub "${apps[@]}" || {
        echo "!!! Batch install failed; retrying one at a time."
        for app in "${apps[@]}"; do
            flatpak install -y --noninteractive --user flathub "$app" \
                || echo "!!! failed: $app"
        done
    }
}

# Function to install apps via Snap
install_snap_apps() {
    banner "Install packages via Snap"

    # 'classic' snaps get unconfined filesystem access, which VS Code needs for
    # extensions and toolchains outside its sandbox. Spotify is a strict snap.
    local classic_snaps=("code")
    local strict_snaps=("spotify")

    local snap_name
    for snap_name in "${classic_snaps[@]}"; do
        sudo snap install "$snap_name" --classic || echo "!!! failed: $snap_name (classic)"
    done
    for snap_name in "${strict_snaps[@]}"; do
        sudo snap install "$snap_name" || echo "!!! failed: $snap_name"
    done
}

# Main script execution
add_apps_repo
install_dnf_packages
install_flatpak_apps
install_snap_apps

banner "Application installation complete. Reboot, then continue the guide."
