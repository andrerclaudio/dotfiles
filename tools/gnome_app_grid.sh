#!/usr/bin/env bash
# Applies a GNOME app-grid layout (folders, order, dash); safe to re-run.
#   gnome_app_grid.sh               apply the layout
#   gnome_app_grid.sh --dry-run     show what would change, touch nothing
#   gnome_app_grid.sh --revert      restore the pre-script state
#   gnome_app_grid.sh --revert DIR  restore a specific backup directory

set -euo pipefail

BACKUP_ROOT="$HOME/.config"
PRISTINE="$BACKUP_ROOT/gnome-app-grid-backup-pristine"

# ------------------- the layout: Fedora-default and fedora/*.sh apps only
# One block per folder: id|name|apps; apps not installed are skipped.

FOLDERS=(
    "office|Office|
        org.libreoffice.LibreOffice.desktop
        org.libreoffice.LibreOffice.writer.desktop
        org.libreoffice.LibreOffice.calc.desktop
        org.libreoffice.LibreOffice.impress.desktop
        org.libreoffice.LibreOffice.draw.desktop
        org.libreoffice.LibreOffice.base.desktop
        org.libreoffice.LibreOffice.math.desktop"

    # VS Code and GNU Octave live in the dash.
    "development|Development|
        pycharm-community.desktop
        nvim.desktop
        org.gnome.GHex.desktop
        org.gnome.meld.desktop
        dev.zed.Zed.desktop"

    "terminals|Terminals|
        org.gnome.Ptyxis.desktop
        com.mitchellh.ghostty.desktop
        Alacritty.desktop"

    # Hidden while Chrome is pinned to the dash.
    "google|Google|
        google-chrome.desktop"

    # FileZilla lives in the dash.
    "downloads|Downloads & Sync|
        syncthing-start.desktop
        syncthing-ui.desktop
        de.haeckerfelix.Fragments.desktop
        org.nickvision.tubeconverter.desktop"

    # Ubuntu and Debian are the entries extra.sh's distrobox containers create.
    "machines|Machines|
        org.gnome.Boxes.desktop
        com.ranfdev.DistroShelf.desktop
        Ubuntu.desktop
        Debian.desktop
        org.gnome.Connections.desktop
        org.remmina.Remmina.desktop"

    "media|Media|
        org.videolan.VLC.desktop
        mpv.desktop
        cliamp.desktop"

    "graphics|Graphics & Video|
        org.gimp.GIMP.desktop
        org.inkscape.Inkscape.desktop
        org.blender.Blender.desktop
        org.kde.kdenlive.desktop
        com.obsproject.Studio.desktop
        org.gnome.Loupe.desktop"

    "monitoring|Monitoring|
        htop.desktop
        org.gnome.SystemMonitor.desktop
        btop.desktop
        org.freedesktop.GnomeAbrt.desktop
        org.gnome.Logs.desktop"

    "disks|Disks & Drives|
        org.gnome.DiskUtility.desktop
        gparted.desktop
        org.gnome.baobab.desktop
        org.fedoraproject.MediaWriter.desktop
        com.raspberrypi.rpi-imager.desktop"

    "settings|Settings|
        com.mattjakeman.ExtensionManager.desktop
        org.gnome.tweaks.desktop
        io.github.flattool.Warehouse.desktop
        org.freedesktop.MalcontentControl.desktop
        org.gnome.Software.desktop
        org.gnome.Yelp.desktop
        org.gnome.Tour.desktop
        org.gnome.Settings.desktop"

    "tools|Utilities|
        org.gnome.Characters.desktop
        org.gnome.clocks.desktop
        org.gnome.font-viewer.desktop
        org.gnome.Evince.desktop
        org.gnome.TextEditor.desktop
        org.gnome.Calculator.desktop
        org.gnome.Calendar.desktop"

    "games|Games|
        0ad.desktop
        com.heroicgameslauncher.hgl.desktop"
)

# Apps outside any folder, placed after the folders in this order.
LOOSE=(
    app.zen_browser.zen.desktop
    org.gnome.Nautilus.desktop
)

# The dash, left to right.
DASH=(
    google-chrome.desktop
    com.microsoft.VSCode.desktop
    com.mitchellh.ghostty.desktop
    md.obsidian.Obsidian.desktop
    org.filezillaproject.Filezilla.desktop
    org.remmina.Remmina.desktop
    org.kde.kdenlive.desktop
    org.octave.Octave.desktop
    org.inkscape.Inkscape.desktop
)

# ------------------------------------------------------------------ plumbing

DRY_RUN=0
SEARCH_DIRS=(
    /usr/share/applications
    /usr/local/share/applications
    "$HOME/.local/share/applications"
    /var/lib/flatpak/exports/share/applications
    "$HOME/.local/share/flatpak/exports/share/applications"
    /var/lib/snapd/desktop/applications
)

say()  { printf '%s\n' "$*"; }
warn() { printf '  ! %s\n' "$*" >&2; }
run()  { if (( DRY_RUN )); then printf '    would: %s\n' "$*"; else "$@"; fi; }

installed() {
    local id=$1 d
    for d in "${SEARCH_DIRS[@]}"; do
        [[ -f "$d/$id" ]] && return 0
    done
    return 1
}

# Sets KEPT to the installed entries of a list, warning about the rest.
keep_installed() {
    local label=$1; shift
    local app
    KEPT=()
    for app in "$@"; do
        if installed "$app"; then
            KEPT+=("$app")
        else
            warn "$label: not installed, skipped: $app"
        fi
    done
}

# Render a bash array as a GVariant string list: ['a', 'b']
as_gvariant_list() {
    local out="[" first=1 item
    for item in "$@"; do
        (( first )) || out+=", "
        out+="'${item}'"
        first=0
    done
    printf '%s]' "$out"
}

backup() {
    local dir
    dir="$BACKUP_ROOT/gnome-app-grid-backup-$(date +%Y%m%d-%H%M%S)"
    if (( DRY_RUN )); then
        say "  would back up to $dir"
        [[ -d "$PRISTINE" ]] || say "  would record pristine state in $PRISTINE"
        return
    fi
    mkdir -p "$dir"
    dconf dump /org/gnome/desktop/app-folders/ > "$dir/app-folders.dconf"
    dconf dump /org/gnome/shell/            > "$dir/shell.dconf"
    say "  backed up to $dir"

    # Written once, so --revert always restores the pre-script state.
    if [[ ! -d "$PRISTINE" ]]; then
        cp -r "$dir" "$PRISTINE"
        say "  recorded pristine state in $PRISTINE"
    fi
}

revert() {
    local dir=${1:-$PRISTINE}
    [[ -d "$dir" ]] || { warn "no such backup: $dir"; exit 1; }
    [[ -f "$dir/app-folders.dconf" && -f "$dir/shell.dconf" ]] \
        || { warn "incomplete backup: $dir"; exit 1; }
    say "Reverting from $dir"
    dconf reset -f /org/gnome/desktop/app-folders/
    dconf load  /org/gnome/desktop/app-folders/ < "$dir/app-folders.dconf"
    dconf load  /org/gnome/shell/               < "$dir/shell.dconf"
    say "Done. Log out and back in to see it."
}

apply() {
    say "Backing up current settings"
    backup

    # Wipe the whole folder tree, stale and hand-made folders included.
    say "Clearing existing folders"
    run dconf reset -f /org/gnome/desktop/app-folders/

    local -a children=() layout_entries=()
    local pos=0 app block id name apps_raw path

    say "Writing ${#FOLDERS[@]} folders"
    for block in "${FOLDERS[@]}"; do
        id=${block%%|*}
        name=${block#*|}; name=${name%%|*}
        apps_raw=${block##*|}

        # Word splitting turns the block into a list.
        # shellcheck disable=SC2086
        keep_installed "$name" $apps_raw

        if (( ${#KEPT[@]} == 0 )); then
            warn "$name: no installed apps, folder omitted"
            continue
        fi

        path="/org/gnome/desktop/app-folders/folders/$id/"
        run dconf write "${path}name"      "'$name'"
        run dconf write "${path}translate" "false"
        run dconf write "${path}apps"      "$(as_gvariant_list "${KEPT[@]}")"

        children+=("$id")
        layout_entries+=("'$id': <{'position': <$pos>}>")
        pos=$(( pos + 1 ))
        printf '  %-18s %2d apps\n' "$name" "${#KEPT[@]}"
    done

    # Loose apps trail the folders.
    keep_installed "loose" "${LOOSE[@]}"
    local -a loose=("${KEPT[@]}")
    for app in "${loose[@]}"; do
        layout_entries+=("'$app': <{'position': <$pos>}>")
        pos=$(( pos + 1 ))
    done

    run dconf write /org/gnome/desktop/app-folders/folder-children \
        "$(as_gvariant_list "${children[@]}")"

    # One page, every entry positioned; joined by hand, as IFS would change run().
    local layout_str="" entry
    for entry in "${layout_entries[@]}"; do
        [[ -n $layout_str ]] && layout_str+=", "
        layout_str+="$entry"
    done
    run dconf write /org/gnome/shell/app-picker-layout "[{${layout_str}}]"

    keep_installed "dash" "${DASH[@]}"
    say "Pinning ${#KEPT[@]} apps to the dash"
    run dconf write /org/gnome/shell/favorite-apps "$(as_gvariant_list "${KEPT[@]}")"

    say
    local summary="$pos grid entries (${#children[@]} folders + ${#loose[@]} loose)"
    if (( DRY_RUN )); then
        say "Would write $summary. Nothing changed."
    else
        say "Wrote $summary"
        say
        say "Log out and back in to see it."
        say "Revert with: $0 --revert"
    fi
}

case "${1:-}" in
    --dry-run) DRY_RUN=1; apply ;;
    --revert)  shift; revert "${1:-}" ;;
    -h|--help) sed -n '2,6p' "$0" | sed 's/^# \?//' ;;
    "")        apply ;;
    *)         warn "unknown option: $1"; exit 2 ;;
esac
