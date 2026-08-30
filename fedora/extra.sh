#!/bin/bash
#
# RUN ORDER:  core.sh  ->  apps.sh  ->  extra.sh
# Requires apps.sh to have run first (the cargo builds need a C compiler from
# development-tools plus openssl-devel and pkgconf-pkg-config) and Oh My Zsh to
# be installed already.
#
#

# -u catches unset variables (typos, empty paths). No -e on purpose: a single
# failed package should not abort the whole run.
set -uo pipefail

LOG_FILE="$HOME/fedora-setup-extra.log"

((EUID)) || { echo "Run this as your normal user, not with sudo."; exit 1; }

exec > >(tee -a "$LOG_FILE") 2>&1
echo "Logging this run to $LOG_FILE"

echo "# -----------------------------------------------------------------------#"
echo "# Starting Extra Configurations & Installations                          #"
echo "# -----------------------------------------------------------------------#"

# Clone if absent, fast-forward if already there, so the script can be re-run.
# Returns non-zero on failure so callers can skip the symlink that follows -
# a symlink to a missing clone is worse than no symlink at all.
clone_or_update() {
    local url="$1" dest="$2"

    if [[ -d "$dest/.git" ]]; then
        echo "     already present, updating: $dest"
        # A shallow clone cannot fast-forward across a force-push; keeping the
        # existing checkout is fine.
        git -C "$dest" pull --ff-only || echo "     kept the existing copy"
        return 0
    fi

    # A leftover non-git directory (interrupted clone) makes 'git clone' fail on
    # every future run, so move it aside.
    [[ -e "$dest" ]] && mv "$dest" "$dest.bak.$(date +%s)"

    git clone --depth 1 "$url" "$dest"
}

# 1. Install ZSH Plugins
echo "---> Installing ZSH Plugins..."
# ZSH_CUSTOM is a plain (non-exported) zsh variable set by oh-my-zsh.sh, so a
# bash script never inherits it. Without this default the paths below expand to
# "/plugins/..." and every clone fails with permission denied.
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [[ -d "$HOME/.oh-my-zsh" ]]; then
    mkdir -p "${ZSH_CUSTOM}/plugins"
    clone_or_update https://github.com/zsh-users/zsh-autosuggestions.git \
        "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
    clone_or_update https://github.com/zsh-users/zsh-syntax-highlighting.git \
        "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"
    clone_or_update https://github.com/marlonrichert/zsh-autocomplete.git \
        "${ZSH_CUSTOM}/plugins/zsh-autocomplete"
    clone_or_update https://github.com/TamCore/autoupdate-oh-my-zsh-plugins.git \
        "${ZSH_CUSTOM}/plugins/autoupdate"
else
    echo "!!! SKIPPED: Oh My Zsh is not installed at ~/.oh-my-zsh."
fi

# 2. Install Nerd Fonts
echo "---> Installing JetBrainsMono Nerd Font..."
# ~/.local/share/fonts is the current path (~/.fonts is deprecated). The tarball
# lands in a temp file rather than the current directory, and fc-cache registers
# the fonts without waiting for a re-login.
FONT_DIR="$HOME/.local/share/fonts/JetBrainsMono"
FONT_TAR=$(mktemp -t JetBrainsMono.XXXXXX.tar.xz)
mkdir -p "$FONT_DIR"
if curl -fsSL -o "$FONT_TAR" \
    https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz \
    && tar -xf "$FONT_TAR" -C "$FONT_DIR"; then
    fc-cache -f "$FONT_DIR"
    echo "     installed to $FONT_DIR"
else
    echo "!!! Font install failed, skipping."
fi
rm -f "$FONT_TAR"

# 3. Install Rust & Cargo Apps (Unattended)
echo "---> Installing Rust and Cargo utilities..."
if [[ ! -x "$HOME/.cargo/bin/cargo" ]]; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

if [[ -f "$HOME/.cargo/env" ]]; then
    # shellcheck source=/dev/null
    source "$HOME/.cargo/env"

    # --locked builds each crate against the Cargo.lock its author published,
    # instead of re-resolving to the newest semver-compatible versions.
    cargo install --locked tock pueue dysk cargo-update
else
    echo "!!! rustup failed, skipping cargo installs."
fi

# 4. Install Atuin
echo "---> Installing Atuin..."
# Skipped when already present: the installer is not idempotent and appends its
# shell-init block to ~/.zshrc on every run.
if command -v atuin >/dev/null 2>&1; then
    echo "     already present, skipping (re-run setup.atuin.sh to update)"
else
    curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
fi

# 5. Configure Eza Theme
echo "---> Configuring Eza Gruvbox theme..."
# Only symlink on a successful clone: a broken ~/.config/eza/theme.yml makes
# every eza invocation fail, and .zshrc aliases 'e' to eza.
mkdir -p ~/.config/eza
if clone_or_update https://github.com/eza-community/eza-themes.git \
    ~/.config/eza/eza-themes; then
    ln -sfn ~/.config/eza/eza-themes/themes/gruvbox-dark.yml ~/.config/eza/theme.yml
fi

# 6. Gruvbox Plus Icon Pack
echo "---> Installing Gruvbox Icons..."
# Application data, so it lives under ~/.local/share; only the symlink that
# Gnome Tweaks reads goes in ~/.icons.
ICON_SRC="$HOME/.local/share/gruvbox-plus-icon-pack"
mkdir -p ~/.icons
if clone_or_update https://github.com/SylEleuth/gruvbox-plus-icon-pack.git "$ICON_SRC"; then
    # -n so a re-run replaces the link rather than nesting inside its target
    ln -sfn "$ICON_SRC/Gruvbox-Plus-Dark" ~/.icons/Gruvbox-Plus-Dark
fi

# 7. Install Repo tool
echo "---> Installing Google Repo Tool..."
# -f matters: without it an HTTP error page gets written to disk and marked
# executable. Downloaded to a temp file first so a failed run cannot destroy a
# working copy.
mkdir -p ~/.local/bin
REPO_TMP=$(mktemp -t repo.XXXXXX)
if curl -fsSL -o "$REPO_TMP" \
    https://commondatastorage.googleapis.com/git-repo-downloads/repo; then
    chmod a+x "$REPO_TMP"
    mv -f "$REPO_TMP" ~/.local/bin/repo
    echo "     installed to ~/.local/bin/repo"
else
    echo "!!! Repo tool download failed, skipping."
    rm -f "$REPO_TMP"
fi

# 8. Install Zed Editor
echo "---> Installing Zed..."
# Official installer from https://zed.dev/download. It drops a prebuilt binary
# in ~/.local/bin/zed plus the app itself in ~/.local/share/zed.app, so no root
# is needed. -f matters here: without it an HTTP error page gets piped into sh.
if [[ -x "$HOME/.local/bin/zed" ]]; then
    echo "     already present, skipping (update from inside Zed)"
else
    curl -fsSL https://zed.dev/install.sh | sh
fi

# 9. Install Ollama
echo "---> Installing Ollama..."
# Official installer from https://github.com/ollama/ollama (https://ollama.com/install.sh).
# Installs the ollama binary and configures the systemd service (may prompt for sudo).
# -f matters here: without it an HTTP error page gets piped into sh.
if command -v ollama >/dev/null 2>&1; then
    echo "     already present, skipping (run 'curl -fsSL https://ollama.com/install.sh | sh' to update)"
else
    curl -fsSL https://ollama.com/install.sh | sh
fi

# 10. Install Herdr
echo "---> Installing Herdr..."
if command -v herdr >/dev/null 2>&1; then
    echo "     already present, skipping (run 'curl -fsSL https://herdr.dev/install.sh | sh' to update)"
else
    curl -fsSL https://herdr.dev/install.sh | sh
fi

# 11. Install Antigravity CLI
echo "---> Installing Antigravity CLI..."
if command -v agy >/dev/null 2>&1; then
    echo "     already present, skipping (run 'curl -fsSL https://antigravity.google/cli/install.sh | bash' to update)"
else
    curl -fsSL https://antigravity.google/cli/install.sh | bash
fi

# 12. Deploy dotfiles (lnko)
echo "---> Deploying dotfiles..."
# This script lives at <clone>/fedora/extra.sh, so its own path finds the
# clone regardless of where it was checked out (e.g. ~/Downloads/dotfiles).
# Copying packages/ into ~/.dotfiles - rather than linking straight from the
# clone - means the clone can be deleted afterwards without breaking anything.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
DOTFILES_DIR="$HOME/.dotfiles"

if [[ -d "$REPO_ROOT/packages" ]]; then
    mkdir -p "$DOTFILES_DIR"
    cp -r "$REPO_ROOT/packages/." "$DOTFILES_DIR/"

    # Package list comes from the directory itself, so dropping a new package
    # folder into packages/ is enough - no need to touch this script.
    PACKAGES=()
    for pkg_dir in "$DOTFILES_DIR"/*/; do
        PACKAGES+=("$(basename "$pkg_dir")")
    done

    if ! command -v lnko >/dev/null 2>&1; then
        curl -fsSL https://raw.githubusercontent.com/Owloops/lnko/main/install.sh | bash
    fi

    if command -v lnko >/dev/null 2>&1; then
        # -b backs conflicting files up to ~/.dotfiles/.lnko-backup/ instead of
        # overwriting them, so a re-run can't silently eat local edits.
        lnko link -d "$DOTFILES_DIR" -t "$HOME" -b "${PACKAGES[@]}"
    else
        echo "!!! lnko install failed, skipping dotfiles link."
        echo "    Run by hand once lnko is installed: lnko link -d $DOTFILES_DIR -t \$HOME ${PACKAGES[*]}"
    fi
else
    echo "!!! SKIPPED: no packages/ directory found next to this script."
fi

echo "# -----------------------------------------------------------------------#"
echo "# Extra scripts installed successfully!                                  #"
echo "# -----------------------------------------------------------------------#"
echo "Reboot it now."
