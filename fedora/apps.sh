#!/bin/bash
#
# Fedora post-install, stage 2 of 3: applications.
#
# RUN ORDER:  core.sh  ->  apps.sh  ->  extra.sh

# -u catches unset variables. No -e: one failed package should not abort the run.
set -uo pipefail

LOG_FILE="$HOME/fedora-setup-apps.log"

# Under sudo, every --user flatpak below would land in root's installation.
((EUID)) || { echo "Run this as your normal user, not with sudo."; exit 1; }

exec > >(tee -a "$LOG_FILE") 2>&1
echo "Logging this run to $LOG_FILE"

# Keep the sudo timestamp alive for the whole run. Output to /dev/null so the
# job cannot hold the log pipe open after the script exits.
sudo -v || exit 1
{ while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done; } >/dev/null 2>&1 &
SUDO_KEEPALIVE_PID=$!
trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null' EXIT

banner() {
    echo "# -----------------------------------------------------------------------#"
    printf '# %-71s#\n' "$1"
    echo "# -----------------------------------------------------------------------#"
}

add_apps_repo() {
    banner "Add 3rd-Party Repositories (LazyGit, Ghostty, Yazi, Chrome, VS Code)"

    # lazygit, ghostty and yazi are not in the official Fedora repos.
    sudo dnf copr enable -y dejan/lazygit
    sudo dnf copr enable -y scottames/ghostty
    sudo dnf copr enable -y lihaohong/yazi

    sudo dnf install -y fedora-workstation-repositories
    sudo dnf config-manager setopt google-chrome.enabled=1

    # https://code.visualstudio.com/docs/setup/linux
    #
    # Import the key first, write the repo only if that worked: under -y dnf
    # would otherwise fetch the key from gpgkey= and auto-accept it.
    echo "---> Adding the Microsoft VS Code repository..."
    if sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc; then
        sudo tee /etc/yum.repos.d/vscode.repo >/dev/null <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
autorefresh=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
    else
        # Any vscode.repo on disk was written by a run that had the key, so it
        # is still valid. Deleting it would drop VS Code out of 'dnf upgrade'.
        echo "!!! Could not fetch the Microsoft signing key; leaving the VS Code repo as-is."
        echo "    'code' will be reported as unavailable below if this is a first run."
    fi

    sudo dnf makecache
}

install_dnf_packages() {
    banner "Install packages via DNF package manager"

    # Separate call so a bad group name is reported clearly.
    sudo dnf group install -y development-tools

    # Alphabetized. Plain names, no .x86_64 suffixes.
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
        "code"                     # VS Code, from the Microsoft repo added above
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
    # a package that cannot be solved. Either one alone still aborts on the other.
    sudo dnf install -y --skip-unavailable --skip-broken "${packages[@]}" 2>&1 | tee "$dnf_log" \
        || echo "!!! dnf install failed - NOTHING may have been installed. See $LOG_FILE."

    # Both skip flags are silent about what they drop, so print it - a renamed
    # or retired package would otherwise go unnoticed for months.
    echo
    echo "---> Packages DNF could not find or resolve (check these by hand):"
    grep -iE "no match for argument|skipping unavailable|not available|broken dependencies" "$dnf_log" \
        || echo "     (none - everything resolved)"
    rm -f "$dnf_log"
}

install_flatpak_apps() {
    banner "Install packages via Flatpak"

    # Alphabetized.
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

    # A batch is much faster, but flatpak refuses all of it over one bad ID -
    # hence the one-at-a-time fallback.
    echo "---> Installing Flathub applications..."
    flatpak install -y --noninteractive --user flathub "${apps[@]}" || {
        echo "!!! Batch install failed; retrying one at a time."
        for app in "${apps[@]}"; do
            flatpak install -y --noninteractive --user flathub "$app" \
                || echo "!!! failed: $app"
        done
    }
}

add_apps_repo
install_dnf_packages
install_flatpak_apps

banner "Application installation complete. Reboot, then continue the guide."
