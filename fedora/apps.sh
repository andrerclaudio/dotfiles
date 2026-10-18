#!/bin/bash
# Fedora post-install, stage 2 of 3 (core.sh -> apps.sh -> extra.sh): applications.

# No -e: one failed step should not abort the run.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=SCRIPTDIR/lib.sh
source "$SCRIPT_DIR/lib.sh"

init_stage "$HOME/fedora-setup-apps.log"

add_apps_repo() {
    banner "Add 3rd-Party Repositories (LazyGit, Ghostty, Yazi, Chrome, VS Code)"

    # lazygit, ghostty and yazi are not in the official Fedora repos.
    sudo dnf copr enable -y dejan/lazygit
    sudo dnf copr enable -y scottames/ghostty
    sudo dnf copr enable -y lihaohong/yazi

    sudo dnf install -y fedora-workstation-repositories
    sudo dnf config-manager setopt google-chrome.enabled=1

    # Import the key first, so dnf -y cannot auto-accept it from gpgkey=.
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
        echo "!!! No Microsoft signing key - leaving the VS Code repo as-is."
    fi

    sudo dnf makecache
}

# Prints what dnf skipped, from the dnf log in $1.
report_skipped_packages() {
    echo
    echo "---> Packages DNF skipped (check these by hand):"
    # Unavailable names, plus each skip heading with its rows.
    awk '
        /^Skipping packages with/ { print; in_rows = 1; found = 1; next }
        in_rows && /^[[:space:]]+[^[:space:]]/ { print; next }
        { in_rows = 0 }
        /^No match for argument/ { print; found = 1 }
        END { if (!found) print "     (none)" }
    ' "$1"
}

install_dnf_packages() {
    banner "Install packages via DNF package manager"

    # Separate call so a bad group name is reported clearly.
    sudo dnf group install -y development-tools

    # Alphabetized. Plain names, no .x86_64 suffixes.
    local packages=(
        "0ad"
        "abrt-desktop"             # crash reporting, with gnome-abrt below
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
        "code"                     # VS Code, from the Microsoft repo above
        "codespell"
        "dbus-devel"
        "distrobox"
        "du-dust"                  # the binary is 'dust'; the package is du-dust
        "expect"
        "eza"
        "fastfetch"
        "fd-find"
        "fedora-packager"
        "ffmpeg-free"
        "flac-devel"
        "flashrom"
        "fontawesome-fonts-all"
        "fzf"
        "gcc-c++"
        "gdb"
        "gdisk"
        "gdk-pixbuf2-devel"
        "ghostty"
        "glib2-devel"
        "gnome-abrt"
        "gnome-shell-extension-pop-shell"
        "gnome-tweaks"
        "gobject-introspection-devel"
        "google-chrome-stable"
        "gparted"
        "grc"
        "gtk4-devel"
        "htop"
        "iperf3"
        "kitty"
        "lazygit"
        "libadwaita-devel"
        "libavcodec-freeworld"
        "libftdi"
        "libjaylink"
        "libusb1-devel"
        "libvorbis-devel"
        "livecd-tools"
        "luarocks"
        "mpv"
        "nano"
        "ncdu"
        "neovim"
        "net-tools"
        "nmap"
        "nodejs-npm"
        "openssl"
        "openssl-devel"            # for cargo-update
        "papirus-icon-theme"
        "picocom"
        "pkgconf-pkg-config"
        "podman-compose"
        "policycoreutils-python-utils"  # semanage, used by tools/change_swap.sh
        "powerline-fonts"
        "pycharm-community"
        "python3-devel"
        "python3-pip"
        "python3-tkinter"
        "qemu"
        "ripgrep"
        "rpi-imager"
        "ShellCheck"               # lint the scripts before committing
        "syncthing"                # started by enable_syncthing below
        "tinyxml2-devel"
        "tio"
        "tldr"
        "tmux"
        "tree"
        "vim-common"
        "xprop"
        "xxd"
        "yazi"
        "yt-dlp"
        "zig"
        "zoxide"
        "zsh"
        "zstd"
    )

    local dnf_log
    dnf_log=$(mktemp -t dnf-install.XXXXXX)

    # Skip names no repo carries and packages that cannot be solved.
    sudo dnf install -y --skip-unavailable --skip-broken "${packages[@]}" 2>&1 | tee "$dnf_log" \
        || echo "!!! dnf install failed - see $LOG_FILE."

    report_skipped_packages "$dnf_log"
    rm -f "$dnf_log"
}

install_flatpak_apps() {
    banner "Install packages via Flatpak"

    # Alphabetized.
    local apps=(
        "app.zen_browser.zen"
        "com.heroicgameslauncher.hgl"
        "com.jeffser.Pigment"
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
        "org.localsend.localsend_app"
        "org.nickvision.tubeconverter"
        "org.octave.Octave"
        "org.remmina.Remmina"
        "org.videolan.VLC"
    )

    # Per app: a batch dies whole over one bad ID. The counter is the progress.
    local app i=0 total=${#apps[@]}
    for app in "${apps[@]}"; do
        printf -- '---> [%2d/%d] %s\n' "$((++i))" "$total" "$app"
        flatpak install -y --noninteractive --user flathub "$app" >/dev/null \
            || echo "!!! failed: $app"
    done
}

install_snap_apps() {
    banner "Install packages via Snap"

    local apps=(
        "spotify"
    )

    local app
    sudo snap wait system seed.loaded
    for app in "${apps[@]}"; do
        sudo snap install "$app" || echo "!!! failed: $app"
    done
}

enable_syncthing() {
    banner "Enable the Syncthing daemon (user service)"

    # The unit ships with the package, but the install above may have skipped it.
    if ! systemctl --user cat syncthing.service >/dev/null 2>&1; then
        echo "!!! SKIPPED: syncthing.service is not installed."
        return
    fi

    # --user, never sudo: the daemon owns the synced files.
    if systemctl --user enable --now syncthing.service; then
        echo "---> Syncthing is running - web UI at http://127.0.0.1:8384"
    else
        echo "!!! Syncthing failed to start."
    fi
}

add_apps_repo
install_dnf_packages
install_flatpak_apps
install_snap_apps
enable_syncthing

banner "Application installation complete. Reboot, then continue the guide."
