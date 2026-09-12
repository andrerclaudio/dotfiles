#!/bin/bash
#
# RUN ORDER:  core.sh  ->  apps.sh  ->  extra.sh
# Needs apps.sh first (the cargo builds want the C toolchain and the -devel
# packages it installs) and Oh My Zsh already in place.

# -u catches unset variables. No -e: one failed package should not abort the run.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

# init_stage also warms sudo: the Ollama installer (step 9) sets up a systemd
# service and would otherwise stop this long run waiting for a password.
init_stage "$HOME/fedora-setup-extra.log"

# The 'have' guards below look for binaries these installers drop in ~/.local/bin
# and ~/.cargo/bin, which a non-login bash may not have on PATH yet.
PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

echo "# -----------------------------------------------------------------------#"
echo "# Starting Extra Configurations & Installations                          #"
echo "# -----------------------------------------------------------------------#"

# Non-zero on failure, so callers can skip whatever depends on the clone.
clone() {
    git clone --depth 1 "$1" "$2"
}

# 1. ZSH plugins
echo "---> Installing ZSH Plugins..."
# oh-my-zsh.sh sets ZSH_CUSTOM without exporting it, so bash needs its own default.
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [[ -d "$HOME/.oh-my-zsh" ]]; then
    mkdir -p "${ZSH_CUSTOM}/plugins"
    clone https://github.com/zsh-users/zsh-autosuggestions.git "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
    clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"
    clone https://github.com/marlonrichert/zsh-autocomplete.git "${ZSH_CUSTOM}/plugins/zsh-autocomplete"
    clone https://github.com/TamCore/autoupdate-oh-my-zsh-plugins.git "${ZSH_CUSTOM}/plugins/autoupdate"
else
    echo "!!! SKIPPED: Oh My Zsh is not installed at ~/.oh-my-zsh."
fi

# 2. Nerd font
echo "---> Installing JetBrainsMono Nerd Font..."
# fc-cache registers the font without waiting for a re-login.
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

# 3. Rust and cargo utilities
echo "---> Installing Rust and Cargo utilities..."
if have rustup; then
    echo "     rustup already installed, skipping."
else
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

if [[ -f "$HOME/.cargo/env" ]]; then
    # shellcheck source=/dev/null
    source "$HOME/.cargo/env"
    # --locked builds each crate against the Cargo.lock its author published.
    cargo install --locked tock pueue dysk cargo-update
else
    echo "!!! rustup failed, skipping cargo installs."
fi

# 4. Atuin
echo "---> Installing Atuin..."
if have atuin; then
    echo "     atuin already installed, skipping."
else
    curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
fi

# 5. Eza gruvbox theme
echo "---> Configuring Eza Gruvbox theme..."
# Link only on a good clone: a broken theme.yml breaks every eza call, and
# .zshrc aliases 'e' to eza.
mkdir -p ~/.config/eza
if clone https://github.com/eza-community/eza-themes.git ~/.config/eza/eza-themes; then
    ln -sfn ~/.config/eza/eza-themes/themes/gruvbox-dark.yml ~/.config/eza/theme.yml
fi

# 6. Gruvbox Plus icon pack
echo "---> Installing Gruvbox Icons..."
# The pack is app data; only the link Gnome Tweaks reads belongs in ~/.icons.
ICON_SRC="$HOME/.local/share/gruvbox-plus-icon-pack"
mkdir -p ~/.icons
if clone https://github.com/SylEleuth/gruvbox-plus-icon-pack.git "$ICON_SRC"; then
    ln -sfn "$ICON_SRC/Gruvbox-Plus-Dark" ~/.icons/Gruvbox-Plus-Dark
fi

# 7. Google repo tool
echo "---> Installing Google Repo Tool..."
# -f on every curl below: without it an HTTP error page is saved or piped to sh.
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

# 8. Zed
echo "---> Installing Zed..."
# Lands in ~/.local/bin/zed and ~/.local/share/zed.app, so no root is needed.
if have zed; then
    echo "     zed already installed, skipping."
else
    curl -fsSL https://zed.dev/install.sh | sh
fi

# 9. Ollama
echo "---> Installing Ollama..."
# Configures a systemd service, so it may prompt for sudo.
if have ollama; then
    echo "     ollama already installed, skipping."
else
    curl -fsSL https://ollama.com/install.sh | sh
fi

# 10. Herdr
echo "---> Installing Herdr..."
if have herdr; then
    echo "     herdr already installed, skipping."
else
    curl -fsSL https://herdr.dev/install.sh | sh
fi

# 11. Antigravity CLI
echo "---> Installing Antigravity CLI..."
if have agy; then
    echo "     antigravity CLI already installed, skipping."
else
    curl -fsSL https://antigravity.google/cli/install.sh | bash
fi

# 12. Claude Code CLI
echo "---> Installing Claude Code CLI..."
# Lands in ~/.local/bin/claude, so no root is needed.
if have claude; then
    echo "     claude already installed, skipping."
else
    curl -fsSL https://claude.ai/install.sh | bash
fi

# 13. Configs
echo "---> Copying configs into ~/.config..."
# config/ mirrors ~/.config exactly, so this copy needs no exceptions: the one
# file that belongs in $HOME (.zshrc) lives at the repo root, not here.
if [[ -d "$REPO_ROOT/config" ]]; then
    mkdir -p "$HOME/.config"
    cp -r "$REPO_ROOT/config/." "$HOME/.config/"
else
    echo "!!! SKIPPED: no config/ directory found next to this script."
fi

# 14. Home dotfiles
echo "---> Installing ~/.zshrc..."
# Replaces the .zshrc the Oh My Zsh installer wrote, keeping the old one as
# ~/.zshrc.bak when it differed. Done here rather than as a manual step in the
# guide, so the shell config ships with everything else.
if [[ -f "$REPO_ROOT/.zshrc" ]]; then
    if [[ -f "$HOME/.zshrc" ]] && ! cmp -s "$REPO_ROOT/.zshrc" "$HOME/.zshrc"; then
        cp -f "$HOME/.zshrc" "$HOME/.zshrc.bak"
        echo "     previous ~/.zshrc saved as ~/.zshrc.bak"
    fi
    cp -f "$REPO_ROOT/.zshrc" "$HOME/.zshrc"
    echo "     installed $HOME/.zshrc"
else
    echo "!!! SKIPPED: no .zshrc found at the repo root."
fi

# 15. TPM (Tmux Plugin Manager)
echo "---> Installing the Tmux Plugin Manager..."
# ~/.tmux/plugins/tpm is the path the last line of tmux.conf runs. The plugins
# go in with 'prefix + I'.
clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"

echo "# -----------------------------------------------------------------------#"
echo "# Extra scripts installed successfully!                                  #"
echo "# -----------------------------------------------------------------------#"
echo "Reboot it now."
