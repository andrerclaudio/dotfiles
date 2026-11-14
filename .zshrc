# ——— PATHS & ENVIRONMENT ——————————————————————————————————————————————
# Allow trailing '#' comments at the prompt.
setopt INTERACTIVE_COMMENTS

export ZSH="$HOME/.oh-my-zsh"
export LANG="en_US.UTF-8"
export LANGUAGE="en_US:en"
export BAT_THEME="gruvbox-dark"
export EDITOR="nano"
export VISUAL="$EDITOR"

# Deduplicate PATH; prepend ~/.local/bin.
typeset -U path
path=("$HOME/.local/bin" $path)

# Rust/Cargo PATH setup.
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# ——— OH-MY-ZSH CONFIGURATION ——————————————————————————————————————————
ZSH_THEME="agnoster"
zstyle ':omz:update' mode auto
HIST_STAMPS="dd.mm.yyyy"
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#458588'

plugins=(
  git
  autoupdate
  zsh-autosuggestions
  zsh-syntax-highlighting   # must stay last
)

# Load Oh My Zsh (guarded).
if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
    source "$ZSH/oh-my-zsh.sh"
else
    print -u2 "oh-my-zsh not found at $ZSH; running a plain zsh."
fi

# ——— HISTORY SETTINGS —————————————————————————————————————————————————
HISTFILE="$HOME/.zsh_history"
HISTSIZE=1000000
SAVEHIST=1000000

# Extras not set by Oh My Zsh.
setopt HIST_REDUCE_BLANKS       # strip extra whitespace
setopt HIST_IGNORE_ALL_DUPS     # remove older duplicates

# ——— ALIASES & FUNCTIONS ——————————————————————————————————————————————
alias my-ip="ip -c -h -s addr"
alias e="eza -lbhHigaUm --git --group-directories-first --icons=auto --color-scale=all --colour=auto"
alias zoom="tree -shaCL 2 --du"

# bat without the pager.
if (( $+commands[bat] )); then
    alias b="bat --paging=never"
fi

# Man pages through bat, in the BAT_THEME colors.
if (( $+commands[bat] )); then
    export MANROFFOPT="-c"
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi

# yazi: cd into its last visited directory on exit.
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [[ -n "$cwd" && "$cwd" != "$PWD" ]]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

# Update everything; missing tools are skipped.
function update() {
    local hdr="\n%F{blue}%B::%b %F{cyan}%B"
    local end="%b%f"
    local skip="%F{yellow}  ⏭  Skipped:%f"

    print -P "\n%F{green}%B🚀 Starting full system update...%b%f"

    print -P "${hdr}📦 System Packages (DNF)${end}"
    # Do not return here: the rest of the function is independent of dnf.
    sudo dnf upgrade --refresh || print -P "%F{red}  ✗ dnf upgrade failed%f"

    print -P "${hdr}🧩 Flatpaks${end}"
    if (( $+commands[flatpak] )); then
        flatpak update
    else
        print -P "${skip} flatpak not installed"
    fi

    print -P "${hdr}🦀 Rust Toolchain${end}"
    if (( $+commands[rustup] )); then
        rustup update
    else
        print -P "${skip} rustup not installed"
    fi

    print -P "${hdr}🐢 Atuin History${end}"
    if (( $+commands[atuin] )); then
        atuin update
    else
        print -P "${skip} atuin not installed"
    fi

    print -P "${hdr}🚚 Cargo Binaries${end}"
    if (( $+commands[cargo] )); then
        # Upgrades only what has a newer release; same list as extra.sh.
        cargo install --locked tock dysk pueue leaf-markdown-viewer
    else
        print -P "${skip} cargo not installed"
    fi

    print -P "${hdr}🐑 Herdr${end}"
    if (( $+commands[herdr] )); then
        herdr update
    else
        print -P "${skip} herdr not installed"
    fi

    print -P "${hdr}🛸 Antigravity CLI${end}"
    if (( $+commands[agy] )); then
        agy update
    else
        print -P "${skip} agy not installed"
    fi

    print -P "${hdr}🤖 Claude CLI${end}"
    if (( $+commands[claude] )); then
        claude update
    else
        print -P "${skip} claude not installed"
    fi

    print -P "${hdr}🎵 cliamp${end}"
    if (( $+commands[cliamp] )); then
        cliamp upgrade
    else
        print -P "${skip} cliamp not installed"
    fi

    print -P "${hdr}🦆 Yazi Flavor${end}"
    if (( $+commands[ya] )); then
        ya pkg upgrade
    else
        print -P "${skip} ya not installed"
    fi

    print -P "\n%F{green}%B✨ All updates complete!%b%f\n"
}

# ——— INITIALIZATIONS & TOOLS ——————————————————————————————————————————

# Disk overview on first interactive shell.
if [[ -o interactive && $SHLVL -eq 1 ]] && (( $+commands[dysk] )); then
    dysk -c label+default || true
fi

# atuin: enhanced shell history.
if [[ -f "$HOME/.atuin/bin/env" ]]; then
    source "$HOME/.atuin/bin/env"
fi
if (( $+commands[atuin] )); then
    eval "$(atuin init zsh)"
fi

# zoxide: smarter cd, initialized last.
if (( $+commands[zoxide] )); then
    eval "$(zoxide init zsh --cmd cd)"
fi

# Auto-attach tmux on SSH login.
if [[ -o interactive ]] && [[ -z "$TMUX" ]] && [[ -n "$SSH_CONNECTION" ]] \
   && (( $+commands[tmux] )); then
    tmux new-session -A -s "$USER"
fi
