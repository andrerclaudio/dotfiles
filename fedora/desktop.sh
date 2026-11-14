#!/bin/bash
# Fedora post-install, stage 4 of 4 (core.sh -> apps.sh -> extra.sh -> desktop.sh): GNOME desktop.

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
    echo "Run this from a terminal inside your GNOME session."
    exit 1
fi

init_stage "$HOME/fedora-setup-desktop.log"

# The running shell only sees new extensions after a login, so edit the setting directly.
add_to_extension_list() {  # $1 enabled-extensions or disabled-extensions, $2 UUID
    local list
    list=$(gsettings get org.gnome.shell "$1")
    list=${list#@as }
    if [[ "$list" == "[]" ]]; then
        list="['$2']"
    else
        list="${list%]}, '$2']"
    fi
    gsettings set org.gnome.shell "$1" "$list"
}

install_extensions() {
    banner "GNOME extensions (extensions.gnome.org)"

    # The download picks the release built for this GNOME Shell version.
    local shell_ver uuid zip
    shell_ver=$(gnome-shell --version | grep -oE '[0-9]+' | head -n 1)
    zip=$(mktemp -t extension.XXXXXX.zip)

    for uuid in "${EXTENSIONS[@]}"; do
        echo "---> $uuid"
        if curl -fsSL -o "$zip" \
            "https://extensions.gnome.org/download-extension/${uuid}.shell-extension.zip?shell_version=${shell_ver}" \
            && gnome-extensions install "$zip"; then
            add_to_extension_list enabled-extensions "$uuid"
        else
            echo "!!! failed: $uuid"
        fi
    done
    rm -f "$zip"

    echo "NOTE: the extensions start after the next login."
}

# Each block below is in 'dconf dump /' format; keys not listed keep their defaults.
set_fonts_and_icons() {
    banner "Fonts and icon theme"
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
    banner "Keyboard shortcuts"
    dconf load / <<'EOF'
[org/gnome/settings-daemon/plugins/media-keys]
custom-keybindings=['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/']
email=['<Super>e']
www=['<Super>w']

[org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0]
binding='<Super>c'
command='code'
name='VsCode'

[org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1]
binding='<Super>t'
command='alacritty'
name='Alacritty'

[org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2]
binding='<Super>g'
command='ghostty'
name='Ghostty'

[org/gnome/desktop/wm/keybindings]
switch-to-workspace-left=['<Control><Alt>Left']
switch-to-workspace-right=['<Control><Alt>Right']
EOF
}

set_default_apps() {
    banner "Default apps (Chrome for the web, Inkscape for SVG)"
    xdg-settings set default-web-browser google-chrome.desktop
    xdg-mime default org.inkscape.Inkscape.desktop image/svg+xml
}

set_snap_icons_style() {
    banner "Snap launchers with the Gruvbox icons"

    # Snaps ignore the icon theme, so a local copy of each launcher points at the icon.
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
            echo "---> Wrote $dst_dir/$launcher"
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
