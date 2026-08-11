#!/bin/bash
#
# Fedora post-install, stage 3 of 3: shell plugins, fonts, Rust toolchain.
#
# RUN ORDER:  core.sh  ->  apps.sh  ->  extra.sh
# Requires apps.sh to have run first (alsa-lib-devel, openssl-devel, dbus-devel
# are needed to compile the crates below) and Oh My Zsh to be installed already.
# Nothing here needs root.

set -uo pipefail

LOG_FILE="$HOME/fedora-setup-extra.log"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "Logging this run to $LOG_FILE"

echo "# -----------------------------------------------------------------------#"
echo "# Starting Extra Configurations & Installations                          #"
echo "# -----------------------------------------------------------------------#"

# Clone if absent, fast-forward if already there, so the script can be re-run
clone_or_update() {
    local url="$1" dest="$2"
    if [[ -d "$dest/.git" ]]; then
        echo "     already present, updating: $dest"
        git -C "$dest" pull --ff-only
    else
        git clone --depth 1 "$url" "$dest"
    fi
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
    echo "!!! Install it (guide Phase 1, step 4) and re-run this script."
fi

# 2. Install Nerd Fonts
echo "---> Installing JetBrainsMono Nerd Font..."
# ~/.local/share/fonts is the current path (~/.fonts is deprecated), the tarball
# goes to /tmp instead of whatever the current directory happens to be, and
# fc-cache registers the fonts without waiting for a re-login.
FONT_DIR="$HOME/.local/share/fonts/JetBrainsMono"
mkdir -p "$FONT_DIR"
if curl -fsSL -o /tmp/JetBrainsMono.tar.xz \
    https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz; then
    tar -xf /tmp/JetBrainsMono.tar.xz -C "$FONT_DIR"
    rm -f /tmp/JetBrainsMono.tar.xz
    fc-cache -f "$FONT_DIR"
    echo "     installed to $FONT_DIR"
else
    echo "!!! Font download failed, skipping."
fi

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
    # eza / ripgrep / zoxide were dropped: apps.sh installs them as RPMs, which
    # saves several minutes of compiling for an identical result.
    cargo install --locked tock pueue dysk spotatui cargo-update
else
    echo "!!! rustup failed, skipping cargo installs."
fi

# 4. Install Atuin
echo "---> Installing Atuin..."
curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh

# 5. Configure Eza Theme
echo "---> Configuring Eza Gruvbox theme..."
mkdir -p ~/.config/eza
clone_or_update https://github.com/eza-community/eza-themes.git \
    ~/.config/eza/eza-themes
ln -sfn ~/.config/eza/eza-themes/themes/gruvbox-dark.yml ~/.config/eza/theme.yml

# 6. Gruvbox Plus Icon Pack
echo "---> Installing Gruvbox Icons..."
mkdir -p ~/.icons ~/Documents
clone_or_update https://github.com/SylEleuth/gruvbox-plus-icon-pack.git \
    ~/Documents/gruvbox-plus-icon-pack
# -n so a re-run replaces the link instead of nesting inside the old target
ln -sfn ~/Documents/gruvbox-plus-icon-pack/Gruvbox-Plus-Dark ~/.icons/Gruvbox-Plus-Dark

# 7. Install Repo tool
echo "---> Installing Google Repo Tool..."
# https + -f: plain http was unauthenticated, and without -f an HTTP error page
# gets written to disk and marked executable.
mkdir -p ~/.local/bin
if curl -fsSL -o ~/.local/bin/repo \
    https://commondatastorage.googleapis.com/git-repo-downloads/repo; then
    chmod a+x ~/.local/bin/repo
    echo "     installed to ~/.local/bin/repo"
else
    echo "!!! Repo tool download failed, skipping."
    rm -f ~/.local/bin/repo
fi

echo "# -----------------------------------------------------------------------#"
echo "# Extra scripts installed successfully!                                  #"
echo "# -----------------------------------------------------------------------#"
echo "Next: reboot, then continue with Phase 2 of Fedora-Config-Guide.md"