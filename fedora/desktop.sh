#!/bin/bash
# Fedora post-install, stage 4 of 4 (core.sh -> apps.sh -> extra.sh -> desktop.sh): GNOME desktop.

# No -e: one failed step should not abort the run.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=SCRIPTDIR/lib.sh
source "$SCRIPT_DIR/lib.sh"

HOST_NAME="notebook"
POWER_PROFILE="performance"

# Installed from extensions.gnome.org.
EXTENSIONS=(
    "blur-my-shell@aunetx"
    "caffeine@patapon.info"
    "clipboard-indicator@tudmotu.com"
    "logomenu@aryan_k"
)

# dconf, gsettings and xdg-settings must act on the GNOME session.
if [[ "${XDG_CURRENT_DESKTOP:-}" != *GNOME* ]]; then
    echo "Run this from a terminal inside your GNOME session."
    exit 1
fi

init_stage "$HOME/fedora-setup-desktop.log"

set_hostname() {
    banner "Hostname ($HOST_NAME)"
    sudo hostnamectl set-hostname "$HOST_NAME"
    hostnamectl hostname
}

set_power_profile() {
    banner "Power profile ($POWER_PROFILE)"
    # Same call as the Quick Settings menu; tuned-ppd keeps it across reboots.
    gdbus call --system --dest org.freedesktop.UPower.PowerProfiles \
        --object-path /org/freedesktop/UPower/PowerProfiles \
        --method org.freedesktop.DBus.Properties.Set \
        org.freedesktop.UPower.PowerProfiles ActiveProfile "<'$POWER_PROFILE'>" >/dev/null \
        || echo "!!! Could not set the power profile."
}

enable_ssh() {
    banner "SSH server (sshd)"
    # Same as the Secure Shell switch in Settings; the firewall already allows SSH.
    sudo systemctl enable --now sshd.service || echo "!!! sshd failed to start."
}

# The running shell only sees new extensions after a login, so edit the setting directly.
enable_extension() {
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
            enable_extension "$uuid"
        else
            echo "!!! failed: $uuid"
        fi
    done
    rm -f "$zip"

    echo "NOTE: the extensions start after the next login."
}

# Each block below is in 'dconf dump /' format; keys not listed keep their defaults.
apply_gnome_settings() {
    banner "GNOME settings (appearance, touchpad, night light, privacy, Files)"
    dconf load / <<'EOF'
[org/gnome/desktop/interface]
accent-color='slate'
clock-format='24h'
color-scheme='prefer-dark'
enable-hot-corners=false
show-battery-percentage=true

[org/gnome/desktop/wm/preferences]
button-layout='appmenu:minimize,maximize,close'

[org/gnome/desktop/peripherals/touchpad]
natural-scroll=false

[org/gnome/desktop/sound]
event-sounds=false

[org/gnome/settings-daemon/plugins/color]
night-light-enabled=true
night-light-temperature=uint32 3680

[org/gnome/system/location]
enabled=true

[org/gnome/desktop/datetime]
automatic-timezone=true

[system/locale]
region='pt_BR.UTF-8'

[org/gnome/desktop/privacy]
report-technical-problems=true

[org/gnome/desktop/search-providers]
disabled=['org.gnome.Software.desktop', 'org.gnome.Nautilus.desktop']

[org/gnome/nautilus/preferences]
default-folder-viewer='list-view'

[org/gnome/nautilus/icon-view]
default-zoom-level='small'

[org/gnome/nautilus/list-view]
default-column-order=['name', 'size', 'type', 'owner', 'group', 'permissions', 'date_modified', 'date_accessed', 'date_created', 'recency', 'detailed_type']
default-visible-columns=['name', 'size', 'type', 'date_modified']
EOF
}

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
    # Super+G opens Ghostty, so Pop Shell's floating toggle is cleared.
    dconf load / <<'EOF'
[org/gnome/settings-daemon/plugins/media-keys]
custom-keybindings=['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/']
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

[org/gnome/shell/extensions/pop-shell]
toggle-floating=@as []

[org/gnome/desktop/wm/keybindings]
switch-to-workspace-left=['<Control><Alt>Left']
switch-to-workspace-right=['<Control><Alt>Right']
EOF
}

set_pop_shell() {
    banner "Pop Shell tiling"
    dconf load / <<'EOF'
[org/gnome/shell/extensions/pop-shell]
active-hint-border-radius=uint32 7
gap-inner=uint32 3
gap-outer=uint32 3
tile-by-default=true
EOF
}

set_extension_settings() {
    banner "Extension settings (Blur my Shell, Caffeine, Clipboard, Logo Menu)"
    # settings-version 7 tells Blur my Shell these are already in its current format.
    dconf load / <<'EOF'
[org/gnome/shell/extensions/blur-my-shell]
pipelines={'pipeline_default': {'name': <'Default'>, 'effects': <[<{'type': <'dual_kawase_blur'>, 'id': <'effect_000000000000'>, 'params': <{'unscaled_radius': <30>, 'brightness': <0.6>}>}>]>}, 'pipeline_migrated_dynamic_blur': {'name': <'Migrated dynamic blur'>, 'effects': <[<{'type': <'dual_kawase_blur'>, 'id': <'effect_migrated_dynamic_blur'>, 'params': <{'unscaled_radius': <60>, 'brightness': <0.6>}>}>]>}}
settings-version=7

[org/gnome/shell/extensions/blur-my-shell/appfolder]
pipeline='pipeline_migrated_dynamic_blur'

[org/gnome/shell/extensions/blur-my-shell/dash-to-dock]
pipeline='pipeline_migrated_dynamic_blur'
static-blur=false
style-dash-to-dock=0

[org/gnome/shell/extensions/blur-my-shell/overview]
style-components=2

[org/gnome/shell/extensions/blur-my-shell/panel]
pipeline='pipeline_migrated_dynamic_blur'
static-blur=false

[org/gnome/shell/extensions/blur-my-shell/window-list]
pipeline='pipeline_migrated_dynamic_blur'

[org/gnome/shell/extensions/caffeine]
enable-mpris=true
restore-state=true

[org/gnome/shell/extensions/clipboard-indicator]
cache-size=19
display-mode=1
history-size=37
move-item-first=true
preview-size=37
strip-text=true
topbar-preview-size=19

[org/gnome/shell/extensions/Logo-menu]
menu-button-icon-image=1
show-activities-button=false
EOF
}

set_default_apps() {
    banner "Default apps (Chrome for the web, Inkscape for SVG)"
    xdg-settings set default-web-browser google-chrome.desktop
    xdg-mime default org.inkscape.Inkscape.desktop image/svg+xml
}

set_spotify_icon() {
    banner "Spotify launcher with the Gruvbox icon"

    # Snaps ignore the icon theme, so a local copy of the launcher points at the icon.
    local src="/var/lib/snapd/desktop/applications/spotify_spotify.desktop"
    local icon="$HOME/.icons/Gruvbox-Plus-Dark/apps/scalable/spotify.svg"
    local dst="$HOME/.local/share/applications/spotify_spotify.desktop"

    if [[ -f "$src" && -f "$icon" ]]; then
        mkdir -p "${dst%/*}"
        sed "s|^Icon=.*|Icon=$icon|" "$src" > "$dst"
        echo "---> Wrote $dst"
    else
        echo "!!! SKIPPED: the Spotify snap or the Gruvbox icons are not installed."
    fi
}

set_hostname
set_power_profile
enable_ssh
install_extensions
apply_gnome_settings
set_fonts_and_icons
set_shortcuts
set_pop_shell
set_extension_settings
set_default_apps
set_spotify_icon

banner "Desktop setup done. Reboot now."
