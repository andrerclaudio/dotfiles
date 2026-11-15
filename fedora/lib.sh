#!/bin/bash
# Shared helpers for the stage scripts; sourced, never run.

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
    ((EUID)) || { echo "!!! Run this as your normal user, not with sudo."; exit 1; }
}

# Copy all output into the log file $1.
start_logging() {
    LOG_FILE="$1"
    exec 3>&1 4>&2
    # The log gets each line's last redraw, without escape codes.
    exec > >(tee >(sed -u 's/\r*$//; s/.*\r//; s/\x1b\[[0-9;?]*[a-zA-Z]//g' >>"$LOG_FILE"); wait $!) 2>&1
    TEE_PID=$!
    echo "---> Logging to $LOG_FILE"
}

# Keep the sudo ticket alive in the background.
start_sudo_keepalive() {
    sudo -v || exit 1
    { trap exit TERM; while true; do sudo -n true; sleep 50 & wait $!; kill -0 "$$" 2>/dev/null || exit; done; } >/dev/null 2>&1 3>&- 4>&- &
    SUDO_KEEPALIVE_PID=$!
}

# Stop the keepalive and clear the sudo ticket.
drop_sudo() {
    kill "$SUDO_KEEPALIVE_PID" 2>/dev/null
    wait "$SUDO_KEEPALIVE_PID" 2>/dev/null
    SUDO_KEEPALIVE_PID=
    sudo -k
}

# Registered on EXIT by each stage.
stage_cleanup() {
    [[ -n "${SUDO_KEEPALIVE_PID:-}" ]] && kill "$SUDO_KEEPALIVE_PID" 2>/dev/null

    # Restoring the fds gives tee its EOF; waiting keeps the last lines.
    if [[ -n "${TEE_PID:-}" ]]; then
        exec 1>&3 2>&4 3>&- 4>&-
        wait "$TEE_PID" 2>/dev/null
    fi
    return 0
}

# One call per stage: refuse root, log, keep the sudo ticket alive, clean up.
init_stage() {
    require_non_root
    start_logging "$1"
    trap stage_cleanup EXIT
    start_sudo_keepalive
}
