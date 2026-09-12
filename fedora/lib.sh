#!/bin/bash
#
# Shared helpers for the Fedora post-install scripts (core.sh, apps.sh,
# extra.sh). Sourced, never executed on its own.
#
# Callers are expected to have run:  set -uo pipefail

banner() {
    echo "# -----------------------------------------------------------------------#"
    printf '# %-71s#\n' "$1"
    echo "# -----------------------------------------------------------------------#"
}

# True when $1 is an executable on PATH. Used to skip installers that already ran.
have() {
    command -v "$1" >/dev/null 2>&1
}

# Under sudo every --user flatpak and every ~/ path would land in root's home.
require_non_root() {
    ((EUID)) || { echo "Run this as your normal user, not with sudo."; exit 1; }
}

# Mirror stdout and stderr into $1. The original fds are parked on 3 and 4 so
# stage_cleanup can restore them and let tee drain - see there.
start_logging() {
    LOG_FILE="$1"
    exec 3>&1 4>&2
    exec > >(tee -a "$LOG_FILE") 2>&1
    TEE_PID=$!
    echo "Logging this run to $LOG_FILE"
}

# Keep the sudo timestamp alive for the whole run. Output to /dev/null so the
# job cannot hold the log pipe open after the script exits.
start_sudo_keepalive() {
    sudo -v || exit 1
    { while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done; } >/dev/null 2>&1 &
    SUDO_KEEPALIVE_PID=$!
}

# Registered on EXIT by init_stage.
stage_cleanup() {
    [[ -n "${SUDO_KEEPALIVE_PID:-}" ]] && kill "$SUDO_KEEPALIVE_PID" 2>/dev/null

    # Restoring the real fds closes the write end of the pipe, so tee sees EOF;
    # waiting for it is what keeps the last lines of the run from being lost.
    if [[ -n "${TEE_PID:-}" ]]; then
        exec 1>&3 2>&4 3>&- 4>&-
        wait "$TEE_PID" 2>/dev/null
    fi
    return 0
}

# One call per stage: refuse root, start the log, keep sudo warm, clean up after.
init_stage() {
    require_non_root
    start_logging "$1"
    trap stage_cleanup EXIT
    start_sudo_keepalive
}
