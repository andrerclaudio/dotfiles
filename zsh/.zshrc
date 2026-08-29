# ——————————————————————————————————————————————————————————————————————
# 1. PATHS & ENVIRONMENT
# ——————————————————————————————————————————————————————————————————————
export ZSH="$HOME/.oh-my-zsh"
export LC_ALL="en_US.UTF-8"
export LANG="en_US.UTF-8"
export LANGUAGE="en_US.UTF-8"
export BAT_THEME="gruvbox-dark"

# 'typeset -U path' keeps $PATH duplicate-free, so re-sourcing this file (or
# nesting shells) does not grow it. $HOME goes first, so a tool installed there
# wins over an older copy in /usr/bin.
typeset -U path
path=("$HOME/.local/bin" $path)

# zsh-autocomplete turns on zsh's recent-directories list, which writes to
# $XDG_DATA_HOME/zsh. Without the directory, every 'cd' prints
#   chpwd_recent_filehandler:29: no such file or directory: .../chpwd-recent-dirs
mkdir -p "${XDG_DATA_HOME:-$HOME/.local/share}/zsh"

# Rust/Cargo. extra.sh installs tock, pueue, dysk and cargo-update into
# ~/.cargo/bin, so without this they are not on PATH and both update() and the
# dysk call below fail with "command not found". rustup writes this file;
# sourcing it is what upstream recommends.
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# ——————————————————————————————————————————————————————————————————————
# 2. OH-MY-ZSH CONFIGURATION
# ——————————————————————————————————————————————————————————————————————
ZSH_THEME="agnoster"
zstyle ':omz:update' mode auto
HIST_STAMPS="dd.mm.yyyy"

plugins=(
  git
  autoupdate
  zsh-autocomplete
  zsh-autosuggestions
  zsh-syntax-highlighting   # must stay last
)

# Guarded so a machine where Oh My Zsh is not installed yet still gets a
# working shell rather than an error on every login.
if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
    source "$ZSH/oh-my-zsh.sh"
else
    print -u2 "oh-my-zsh not found at $ZSH - running a plain zsh."
fi

# ——————————————————————————————————————————————————————————————————————
# 3. HISTORY SETTINGS
# ——————————————————————————————————————————————————————————————————————
# Set AFTER oh-my-zsh.sh, which would otherwise override them with its own
# defaults (SAVEHIST=10000).
#
# zsh uses HISTSIZE for lines kept in memory and SAVEHIST for lines written to
# HISTFILE. Note that HISTFILESIZE, HISTTIMEFORMAT, HISTCONTROL and
# PROMPT_COMMAND are bash variables - zsh ignores them entirely.
HISTFILE="$HOME/.zsh_history"
HISTSIZE=1000000
SAVEHIST=1000000

# Oh My Zsh already sets extended_history, hist_ignore_dups, hist_ignore_space
# and share_history. These two are the ones it does not.
setopt HIST_REDUCE_BLANKS       # trim superfluous whitespace before saving
setopt HIST_VERIFY              # expand !! onto the line instead of running it

# ——————————————————————————————————————————————————————————————————————
# 4. ALIASES & FUNCTIONS
# ——————————————————————————————————————————————————————————————————————
alias fastfetch="fastfetch --logo-padding-top 3 --logo-padding-left 4"
alias my-ip="ip -c -h -s addr"
alias e="eza -lbhHigaUm --git --group-directories-first --icons=auto --color-scale=all --colour=auto --loc"
alias zoom="tree -shaCL 2 --du"

# Guarded, so a missing bat does not leave you without a working cat.
# (Fedora ships the binary as 'bat'; Debian-based distros use 'batcat'.)
if (( $+commands[bat] )); then
    alias cat="bat"
elif (( $+commands[batcat] )); then
    alias cat="batcat"
fi

# yazi wrapper: leave the shell in whatever directory yazi last showed.
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

# Update everything. Each step is skipped when its tool is absent rather than
# aborting, so one missing tool does not stop the steps after it.
function update() {
    print -P "\n%F{green}%B==> Updating System Packages (DNF)...%b%f"
    sudo dnf upgrade --refresh || return 1

    print -P "\n%F{green}%B==> Updating Flatpaks...%b%f"
    if (( $+commands[flatpak] )); then
        flatpak update
    else
        print -P "%F{yellow}   skipped: flatpak not installed%f"
    fi

    print -P "\n%F{green}%B==> Updating Rust Toolchain...%b%f"
    if (( $+commands[rustup] )); then
        rustup update
    else
        print -P "%F{yellow}   skipped: rustup not installed%f"
    fi

    print -P "\n%F{green}%B==> Updating Atuin...%b%f"
    if (( $+commands[atuin] )); then
        atuin update
    else
        print -P "%F{yellow}   skipped: atuin not installed%f"
    fi

    print -P "\n%F{green}%B==> Updating Cargo Binaries...%b%f"
    if (( $+commands[cargo-install-update] )); then
        cargo install-update -a
    else
        print -P "%F{yellow}   skipped: cargo install cargo-update%f"
    fi

    print -P "\n%F{green}%B==> Updating Herdr...%b%f"
    if (( $+commands[herdr] )); then
        herdr update
    else
        print -P "%F{yellow}   skipped: herdr not installed%f"
    fi

    print -P "\n%F{green}%B==> Updating Antigravity CLI...%b%f"
    if (( $+commands[agy] )); then
        agy update
    else
        print -P "%F{yellow}   skipped: agy not installed%f"
    fi

    print -P "\n%F{green}%B==> All updates complete!%b%f"
}

# ——————————————————————————————————————————————————————————————————————
# 5. INITIALIZATIONS & TOOLS
# ——————————————————————————————————————————————————————————————————————
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#458588'

# Disk overview once per top-level interactive shell.
if [[ -o interactive && $SHLVL -eq 1 ]] && (( $+commands[dysk] )); then
    dysk -c label+default || true
fi

if [[ -s /etc/grc.zsh ]]; then
    source /etc/grc.zsh
fi

# '--cmd cd' hands cd to zoxide while keeping 'cd -', bare 'cd' and completion
# intact. Guarded, so without zoxide cd stays the shell builtin.
if (( $+commands[zoxide] )); then
    eval "$(zoxide init zsh --cmd cd)"
fi

# Guarded: on a machine where extra.sh's atuin install did not finish, an
# unguarded source + init prints two errors in every new shell.
if [[ -f "$HOME/.atuin/bin/env" ]]; then
    source "$HOME/.atuin/bin/env"
fi
if (( $+commands[atuin] )); then
    eval "$(atuin init zsh)"
fi

# Attach to a tmux session when arriving over SSH.
# '[[ -o interactive ]]' is the reliable test here - zsh gives PS1 a default value
# even in non-interactive shells, so checking $PS1 would always pass.
if [[ -o interactive ]] && [[ -z "$TMUX" ]] && [[ -n "$SSH_CONNECTION" ]] \
   && (( $+commands[tmux] )); then
    tmux attach-session -t "$USER" || tmux new-session -s "$USER"
fi