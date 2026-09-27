#!/bin/bash
# Fedora post-install, stage 3 of 3 (core.sh -> apps.sh -> extra.sh): tools and configs.

# No -e: one failed step should not abort the run.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

# init_stage warms sudo: the Ollama and superfile installers (steps 9, 14) need it mid-run.
init_stage "$HOME/fedora-setup-extra.log"

# Later steps call binaries the earlier ones drop in these dirs.
PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

banner "Starting Extra Configurations & Installations"

# Non-zero on failure, so callers can skip what depends on the clone.
clone() {
    git clone --depth 1 "$1" "$2"
}

# 1. ZSH plugins
echo "---> Installing ZSH Plugins..."
# oh-my-zsh.sh sets ZSH_CUSTOM without exporting it, so set it here too.
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [[ -d "$HOME/.oh-my-zsh" ]]; then
    mkdir -p "${ZSH_CUSTOM}/plugins"
    clone https://github.com/zsh-users/zsh-autosuggestions.git "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
    clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"
    clone https://github.com/TamCore/autoupdate-oh-my-zsh-plugins.git "${ZSH_CUSTOM}/plugins/autoupdate"
else
    echo "!!! SKIPPED: Oh My Zsh is not installed at ~/.oh-my-zsh."
fi

# 2. Nerd font
echo "---> Installing JetBrainsMono Nerd Font..."
# fc-cache registers the font without a re-login.
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
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

if [[ -f "$HOME/.cargo/env" ]]; then
    # shellcheck source=/dev/null
    source "$HOME/.cargo/env"
    # --locked builds against the Cargo.lock each author published.
    cargo install --locked tock dysk cargo-update
    # pueue and leaf are left unlocked on purpose.
    cargo install pueue leaf-markdown-viewer
else
    echo "!!! rustup failed, skipping cargo installs."
fi

# 4. Atuin
echo "---> Installing Atuin..."
curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh \
    || echo "!!! Atuin install failed."

# 5. Eza gruvbox theme
echo "---> Configuring Eza Gruvbox theme..."
# Link only on a good clone: a broken theme.yml breaks every eza call.
mkdir -p ~/.config/eza
if clone https://github.com/eza-community/eza-themes.git ~/.config/eza/eza-themes; then
    ln -sfn ~/.config/eza/eza-themes/themes/gruvbox-dark.yml ~/.config/eza/theme.yml
fi

# 6. Gruvbox Plus icon pack
echo "---> Installing Gruvbox Icons..."
# Only the link Gnome Tweaks reads belongs in ~/.icons.
ICON_SRC="$HOME/.local/share/gruvbox-plus-icon-pack"
mkdir -p ~/.icons
if clone https://github.com/SylEleuth/gruvbox-plus-icon-pack.git "$ICON_SRC"; then
    ln -sfn "$ICON_SRC/Gruvbox-Plus-Dark" ~/.icons/Gruvbox-Plus-Dark
fi

# 7. Google repo tool
echo "---> Installing Google Repo Tool..."
# -f on every curl: without it an HTTP error page gets saved or piped to sh.
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
# Lands under ~/.local, so no root is needed.
curl -fsSL https://zed.dev/install.sh | sh || echo "!!! Zed install failed."

# 9. Ollama
echo "---> Installing Ollama..."
# Sets up a systemd service, so it may prompt for sudo.
curl -fsSL https://ollama.com/install.sh | sh || echo "!!! Ollama install failed."

# 10. Herdr
echo "---> Installing Herdr..."
curl -fsSL https://herdr.dev/install.sh | sh || echo "!!! Herdr install failed."

# 11. Antigravity CLI
echo "---> Installing Antigravity CLI..."
curl -fsSL https://antigravity.google/cli/install.sh | bash \
    || echo "!!! Antigravity CLI install failed."

# 12. Claude Code CLI
echo "---> Installing Claude Code CLI..."
# Lands in ~/.local/bin, so no root is needed.
curl -fsSL https://claude.ai/install.sh | bash || echo "!!! Claude Code install failed."

# 13. cliamp
echo "---> Installing cliamp..."
# The PATH above makes the installer use ~/.local/bin, so no root is needed.
curl -fsSL https://cliamp.stream/install.sh | sh || echo "!!! cliamp install failed."

# 14. superfile
echo "---> Installing superfile..."
# Moves spf into /usr/local/bin with sudo; its gruvbox config comes with step 15.
curl -fsSL https://superfile.dev/install.sh | bash || echo "!!! superfile install failed."

# 15. Configs
echo "---> Copying configs into ~/.config..."
# config/ mirrors ~/.config exactly; .zshrc lives at the repo root instead.
if [[ -d "$REPO_ROOT/config" ]]; then
    mkdir -p "$HOME/.config"
    cp -r "$REPO_ROOT/config/." "$HOME/.config/"
else
    echo "!!! SKIPPED: no config/ directory found next to this script."
fi

# 16. Pueue daemon
echo "---> Enabling the Pueue daemon..."
# Needs pueued (step 3) and its unit (step 15); daemon-reload loads the unit.
if have pueued; then
    systemctl --user daemon-reload
    systemctl --user enable --now pueued.service \
        || echo "!!! Pueue daemon failed to start."
else
    echo "!!! SKIPPED: pueued is not installed - see step 3."
fi

# 17. Home dotfiles
echo "---> Installing ~/.zshrc..."
# Replaces ~/.zshrc, keeping a differing one as ~/.zshrc.bak.
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

# 18. TPM (Tmux Plugin Manager)
echo "---> Installing the Tmux Plugin Manager..."
# The path tmux.conf runs TPM from; plugins install with 'prefix + I'.
clone https://github.com/tmux-plugins/tpm "$HOME/.config/tmux/plugins/tpm"

# 19. Yazi flavor
echo "---> Installing the Yazi gruvbox-material flavor..."
# After step 15, which copies the theme.toml that selects this flavor.
if have ya; then
    ya pkg add matt-dong-123/gruvbox-material \
        || echo "!!! Yazi flavor install failed, skipping."
else
    echo "!!! SKIPPED: yazi is not installed."
fi

# 20. Ollama models
echo "---> Pulling Ollama models..."
# Several GB and no resume, so each pull is reported on its own.
if have ollama; then
    for model in deepseek-r1:1.5b gemma3:1b qwen3-vl:4b; do
        ollama pull "$model" || echo "!!! failed: $model"
    done
else
    echo "!!! SKIPPED: ollama is not installed - see step 9."
fi

# 21. Distrobox containers
echo "---> Creating the Debian and Ubuntu containers..."
# --home gives each container its own home folder, apart from the host's ~.
DISTROBOX_HOMES="$HOME/Documents/Distrobox"
if have distrobox; then
    DB_PKGS="systemd libpam-systemd pipewire-audio-client-libraries git tmux"
    create_box() {  # $1 name, $2 image
        mkdir -p "$DISTROBOX_HOMES/$1"
        distrobox create --name "$1" --hostname "$1" --init --image "$2" \
            --additional-packages "$DB_PKGS" --home "$DISTROBOX_HOMES/$1" \
            || echo "!!! failed to create $1"
    }
    create_box Debian debian:latest
    create_box Ubuntu ubuntu:24.04
    echo "     enter them with 'distrobox enter Debian' / 'distrobox enter Ubuntu'."
else
    echo "!!! SKIPPED: distrobox is not installed."
fi

# 22. GNOME app grid and dash
echo "---> Laying out the GNOME app grid and dash..."
# Last, so every app it lays out is installed; undo with tools/gnome_app_grid.sh --revert.
if have dconf; then
    bash "$REPO_ROOT/tools/gnome_app_grid.sh" || echo "!!! App grid layout failed."
else
    echo "!!! SKIPPED: dconf is not installed."
fi

banner "Extra scripts installed. Reboot now."
