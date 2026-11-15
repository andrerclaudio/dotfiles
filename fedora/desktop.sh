#!/bin/bash
# Fedora post-install, stage 4 of 4: GNOME desktop.

# No -e: one failed step should not abort the run.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=SCRIPTDIR/lib.sh
source "$SCRIPT_DIR/lib.sh"

# Installed from extensions.gnome.org.
EXTENSIONS=(
    "blur-my-shell@aunetx"
    "caffeine@patapon.info"
    "clipboard-indicator@tudmotu.com"
    "gnome-mosaic@jardon.github.com"
    "logomenu@aryan_k"
)

# dconf, gsettings and xdg-settings must act on the GNOME session.
if [[ "${XDG_CURRENT_DESKTOP:-}" != *GNOME* ]]; then
    echo "!!! Run this from a terminal inside your GNOME session."
    exit 1
fi

# No sudo in this stage, so no init_stage and its password prompt.
require_non_root
start_logging "$HOME/fedora-setup-desktop.log"
trap stage_cleanup EXIT

# Append the extension to the enabled list.
enable_extension() {  # $1 UUID
    local list
    list=$(gsettings get org.gnome.shell enabled-extensions)
    list=${list#@as }
    if [[ "$list" == "[]" ]]; then
        list="['$1']"
    else
        list="${list%]}, '$1']"
    fi
    gsettings set org.gnome.shell enabled-extensions "$list"
}

# True when the extension zip $1 lists GNOME Shell major version $2.
supports_shell() {
    python3 -I - "$1" "$2" <<'EOF'
import json, sys, zipfile
meta = json.load(zipfile.ZipFile(sys.argv[1]).open("metadata.json"))
sys.exit(sys.argv[2] not in {v.split(".")[0] for v in meta.get("shell-version", [])})
EOF
}

install_extensions() {
    banner "Installing GNOME extensions"

    # Skip any extension without a release for this shell.
    local shell_ver uuid zip
    shell_ver=$(gnome-shell --version | grep -oE '[0-9]+' | head -n 1)
    zip=$(mktemp -t extension.XXXXXX.zip)

    for uuid in "${EXTENSIONS[@]}"; do
        echo "---> $uuid"
        if ! curl --proto '=https' --tlsv1.2 -fsSL -o "$zip" \
            "https://extensions.gnome.org/download-extension/${uuid}.shell-extension.zip?shell_version=${shell_ver}"; then
            echo "!!! failed: $uuid"
        elif ! supports_shell "$zip" "$shell_ver"; then
            echo "!!! SKIPPED: $uuid has no release for GNOME Shell $shell_ver."
        elif gnome-extensions install "$zip"; then
            enable_extension "$uuid"
        else
            echo "!!! failed: $uuid"
        fi
    done
    rm -f "$zip"

    echo "NOTE: the extensions start after the next login."
}

# 'dconf dump /' format; unlisted keys stay as they are.
set_fonts_and_icons() {
    banner "Setting the fonts and icon theme"
    # The font comes from extra.sh step 4, the icons from step 8.
    dconf load / <<'EOF'
[org/gnome/desktop/interface]
document-font-name='JetBrainsMonoNL Nerd Font Mono 12'
font-name='JetBrainsMonoNL Nerd Font Mono 11'
icon-theme='Gruvbox-Plus-Dark'
monospace-font-name='JetBrainsMonoNL Nerd Font Mono 11'
EOF
}

set_shortcuts() {
    banner "Setting keyboard shortcuts"
    dconf load / <<'EOF'
[org/gnome/settings-daemon/plugins/media-keys]
custom-keybindings=['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/']
email=['<Super>e']
www=['<Super>w']

[org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0]
binding='<Super>c'
command='code'
name='VS Code'

[org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1]
binding='<Super>t'
command='alacritty'
name='Alacritty'

[org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2]
binding='<Super>g'
command='ghostty'
name='Ghostty'
EOF
}

set_default_apps() {
    banner "Setting default apps"
    xdg-settings set default-web-browser google-chrome.desktop
    xdg-mime default org.inkscape.Inkscape.desktop image/svg+xml
}

set_snap_icons_style() {
    banner "Pointing snap launchers at the Gruvbox icons"

    # A local copy of each launcher points at its Gruvbox icon.
    local src_dir="/var/lib/snapd/desktop/applications"
    local icon_dir="$HOME/.icons/Gruvbox-Plus-Dark/apps/scalable"
    local dst_dir="$HOME/.local/share/applications"
    local -A icons=(
        [pycharm_pycharm.desktop]="pycharm"
        [spotify_spotify.desktop]="spotify"
    )

    local launcher icon
    mkdir -p "$dst_dir"
    for launcher in "${!icons[@]}"; do
        icon="$icon_dir/${icons[$launcher]}.svg"
        if [[ -f "$src_dir/$launcher" && -f "$icon" ]]; then
            sed "s|^Icon=.*|Icon=$icon|" "$src_dir/$launcher" > "$dst_dir/$launcher"
            echo "     wrote $dst_dir/$launcher"
        else
            echo "!!! SKIPPED: $launcher or its Gruvbox icon is not installed."
        fi
    done
}

install_extensions
set_fonts_and_icons
set_shortcuts
set_default_apps
set_snap_icons_style

banner "Desktop setup done. Reboot now."
