#!/bin/bash
#
# Shared helpers for core.sh, apps.sh and extra.sh. Sourced, never run directly.
# Callers are expected to have run:  set -uo pipefail

banner() {
    echo "# -----------------------------------------------------------------------#"
    printf '# %-71s#\n' "$1"
    echo "# -----------------------------------------------------------------------#"
}

# True when $1 is on PATH.
have() {
    command -v "$1" >/dev/null 2>&1
}

# Under sudo, --user flatpaks and ~/ paths would land in root's home.
require_non_root() {
    ((EUID)) || { echo "Run this as your normal user, not with sudo."; exit 1; }
}

# Log to $1, also published as $LOG_FILE. Real fds parked on 3 and 4.
start_logging() {
    LOG_FILE="$1"
    exec 3>&1 4>&2
    # Screen keeps the progress bars; the log gets the last redraw, no escapes.
    exec > >(tee >(sed -u 's/\r*$//; s/.*\r//; s/\x1b\[[0-9;?]*[a-zA-Z]//g' >>"$LOG_FILE")) 2>&1
    TEE_PID=$!
    echo "Logging this run to $LOG_FILE"
}

# Keep the sudo timestamp alive. Silenced so it cannot hold the log pipe open.
start_sudo_keepalive() {
    sudo -v || exit 1
    { while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done; } >/dev/null 2>&1 &
    SUDO_KEEPALIVE_PID=$!
}

# Registered on EXIT by init_stage.
stage_cleanup() {
    [[ -n "${SUDO_KEEPALIVE_PID:-}" ]] && kill "$SUDO_KEEPALIVE_PID" 2>/dev/null

    # Restoring the fds gives tee its EOF; waiting keeps the last lines.
    if [[ -n "${TEE_PID:-}" ]]; then
        exec 1>&3 2>&4 3>&- 4>&-
        wait "$TEE_PID" 2>/dev/null
    fi
    return 0
}

# One call per stage: refuse root, log, keep sudo warm, clean up after.
init_stage() {
    require_non_root
    start_logging "$1"
    trap stage_cleanup EXIT
    start_sudo_keepalive
}
