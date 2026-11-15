#!/usr/bin/env bash
# Lists the Gmail PWA under Default Apps > Mail.
#   gmail_pwa_mailto.sh            apply; run again whenever Chrome rewrites the Gmail launcher
#   gmail_pwa_mailto.sh --revert   hand the launcher back to Chrome and remove the wrapper

set -euo pipefail

# Gmail's Chrome app id and the Chrome profile folder.
APP_ID="fmgjjmmmlfnkbppncabfkddbjimcfncm"
PROFILE="Default"
CHROME="/opt/google/chrome/google-chrome"

APPS_DIR="$HOME/.local/share/applications"
LAUNCHER="$APPS_DIR/chrome-${APP_ID}-${PROFILE}.desktop"
WRAPPER="$HOME/.local/bin/gmail-pwa"
MIME="x-scheme-handler/mailto"
TMP=""
trap 'rm -f "$TMP"' EXIT

# Prints the launcher with Exec set to $1; $2 adds or removes mailto.
rewrite_launcher() {
    awk -v cmd="$1" -v mode="$2" -v mime="$MIME" '
        function mime_types(   n, parts, i, out) {
            n = split(types, parts, ";")
            for (i = 1; i <= n; i++)
                if (parts[i] != "" && parts[i] != mime) out = out parts[i] ";"
            if (mode == "add") out = out mime ";"
            return out
        }
        FNR == 1 { group = "" }
        /^\[/    { group = $0 }
        NR == FNR { if (group == "[Desktop Entry]" && /^MimeType=/) types = substr($0, 10); next }
        group == "[Desktop Entry]" && /^MimeType=/ { next }
        group == "[Desktop Entry]" && /^Exec=/ {
            print "Exec=" cmd
            line = mime_types()
            if (line != "") print "MimeType=" line
            next
        }
        { print }
    ' "$LAUNCHER" "$LAUNCHER"
}

# Writes $LAUNCHER from rewrite_launcher's output, only if it changes.
update_launcher() {
    TMP=$(mktemp)
    rewrite_launcher "$@" > "$TMP"
    grep -q '^Exec=' "$TMP" || { echo "!!! ${LAUNCHER##*/} has no Exec line, so it was left untouched."; exit 1; }
    if cmp -s "$TMP" "$LAUNCHER"; then
        echo "---> ${LAUNCHER##*/} is already up to date."
    else
        echo "---> Rewriting ${LAUNCHER##*/}..."
        cat "$TMP" > "$LAUNCHER"
    fi
}

# Writes a wrapper that opens Gmail, or compose for a mailto: link.
write_wrapper() {
    echo "---> Writing $WRAPPER..."
    mkdir -p "${WRAPPER%/*}"
    {
        echo '#!/usr/bin/env bash'
        echo '# Gmail PWA launcher, written by gmail_pwa_mailto.sh.'
        printf 'chrome=(%q --profile-directory=%q --app-id=%q)\n' "$CHROME" "$PROFILE" "$APP_ID"
        cat <<'EOF'
if [[ ${1:-} == mailto:* ]]; then
    url=$(python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1], safe=""))' "$1")
    exec "${chrome[@]}" --app-launch-url-for-shortcuts-menu-item="https://mail.google.com/mail/?extsrc=mailto&url=$url"
fi
exec "${chrome[@]}"
EOF
    } > "$WRAPPER"
    chmod +x "$WRAPPER"
}

# GNOME reads the handler list from this cache.
refresh_cache() {
    if command -v update-desktop-database >/dev/null; then
        update-desktop-database -q "$APPS_DIR"
    fi
}

require_launcher() {
    if [[ ! -f $LAUNCHER ]]; then
        echo "!!! $LAUNCHER not found."
        echo "    Install Gmail as an app from Chrome first."
        exit 1
    fi
}

apply() {
    require_launcher
    write_wrapper
    update_launcher "$WRAPPER %u" add
    refresh_cache

    if gio mime "$MIME" 2>/dev/null | grep -qF "${LAUNCHER##*/}"; then
        echo "Done. Reopen Settings > Apps > Default Apps and pick Gmail under Mail."
        echo "Test with: xdg-open 'mailto:test@example.com?subject=Hello'"
    else
        echo "!!! GNOME still doesn't list Gmail for $MIME; check with: gio mime $MIME"
        exit 1
    fi
}

revert() {
    require_launcher
    update_launcher "$CHROME --profile-directory=$PROFILE --app-id=$APP_ID" remove
    rm -f "$WRAPPER"
    refresh_cache
    echo "Done. Pick another Mail app in Settings > Apps > Default Apps."
}

case "${1:-}" in
    --revert)  revert ;;
    -h|--help) sed -n '2,4p' "$0" | sed 's/^# \?//' ;;
    "")        apply ;;
    *)         echo "!!! unknown option: $1"; exit 2 ;;
esac
