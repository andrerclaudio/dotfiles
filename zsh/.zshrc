# ——————————————————————————————————————————————————————————————————————
# PATHS & ENVIRONMENT
# ——————————————————————————————————————————————————————————————————————
export ZSH="$HOME/.oh-my-zsh"
export LANG="en_US.UTF-8"
export LANGUAGE="en_US.UTF-8"
export BAT_THEME="gruvbox-dark"

# Deduplicate PATH; prepend ~/.local/bin.
typeset -U path
path=("$HOME/.local/bin" $path)

# Needed by zsh-autocomplete's recent-directories feature.
[[ -d "${XDG_DATA_HOME:-$HOME/.local/share}/zsh" ]] || mkdir -p "${XDG_DATA_HOME:-$HOME/.local/share}/zsh"

# Rust/Cargo PATH setup.
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# ——————————————————————————————————————————————————————————————————————
# OH-MY-ZSH CONFIGURATION
# ——————————————————————————————————————————————————————————————————————
ZSH_THEME="agnoster"
zstyle ':omz:update' mode auto
HIST_STAMPS="dd.mm.yyyy"
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#458588'

plugins=(
  git
  autoupdate
  zsh-autocomplete
  zsh-autosuggestions
  zsh-syntax-highlighting   # must stay last
)

# Load Oh My Zsh (guarded).
if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
    source "$ZSH/oh-my-zsh.sh"
else
    print -u2 "oh-my-zsh not found at $ZSH - running a plain zsh."
fi

# ——————————————————————————————————————————————————————————————————————
# HISTORY SETTINGS
# ——————————————————————————————————————————————————————————————————————
# Set AFTER oh-my-zsh.sh to avoid being overridden.
HISTFILE="$HOME/.zsh_history"
HISTSIZE=1000000
SAVEHIST=1000000

# Extras not set by Oh My Zsh.
setopt HIST_REDUCE_BLANKS       # strip extra whitespace
setopt HIST_VERIFY              # expand !! before executing
setopt HIST_IGNORE_ALL_DUPS     # remove older duplicates from history
setopt HIST_SAVE_NO_DUPS        # do not write duplicates to history file
setopt HIST_FIND_NO_DUPS        # do not cycle duplicates in search

# ——————————————————————————————————————————————————————————————————————
# ALIASES & FUNCTIONS
# ——————————————————————————————————————————————————————————————————————
alias fastfetch="fastfetch --logo-padding-top 3 --logo-padding-left 4"
alias my-ip="ip -c -h -s addr"
alias e="eza -lbhHigaUm --git --group-directories-first --icons=auto --color-scale=all --colour=auto"
alias zoom="tree -shaCL 2 --du"

# Use bat as cat (Fedora: bat, Debian: batcat).
if (( $+commands[bat] )); then
    alias cat="bat"
elif (( $+commands[batcat] )); then
    alias cat="batcat"
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
    sudo dnf upgrade --refresh || return 1

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
    if (( $+commands[cargo-install-update] )); then
        cargo install-update -a
    else
        print -P "${skip} cargo-update not installed"
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

    print -P "\n%F{green}%B✨ All updates complete!%b%f\n"
}

# ——————————————————————————————————————————————————————————————————————
# INITIALIZATIONS & TOOLS
# ——————————————————————————————————————————————————————————————————————

# Disk overview on first interactive shell.
if [[ -o interactive && $SHLVL -eq 1 ]] && (( $+commands[dysk] )); then
    dysk -c label+default || true
fi

# grc: colorize common commands.
if [[ -s /etc/grc.zsh ]]; then
    source /etc/grc.zsh
fi

# zoxide: replaces cd with smarter navigation.
if (( $+commands[zoxide] )); then
    eval "$(zoxide init zsh --cmd cd)"
fi

# atuin: enhanced shell history.
if [[ -f "$HOME/.atuin/bin/env" ]]; then
    source "$HOME/.atuin/bin/env"
fi
if (( $+commands[atuin] )); then
    eval "$(atuin init zsh)"
fi

# Auto-attach tmux on SSH login.
if [[ -o interactive ]] && [[ -z "$TMUX" ]] && [[ -n "$SSH_CONNECTION" ]] \
   && (( $+commands[tmux] )); then
    tmux attach-session -t "$USER" || tmux new-session -s "$USER"
fi