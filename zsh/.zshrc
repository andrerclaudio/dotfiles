# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="agnoster"

# Setting history length  and stuff related to it
export HISTFILESIZE=1000000
export HISTSIZE=99999
export HISTFILE=~/.zsh_history
export HISTTIMEFORMAT="[%F %T] "
PROMPT_COMMAND="zsh_history -a; $PROMPT_COMMAND"
export HISTCONTROL=ignoredups

zstyle ':omz:update' mode auto

HIST_STAMPS="dd.mm.yyyy"

plugins=(
git
tmux
autoupdate
zsh-autocomplete
zsh-autosuggestions
zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# —————————————————————————
# Run dysk once at terminal startup (ignore errors)
if [[ -o interactive && $SHLVL -eq 1 ]]; then
  dysk -c label+default || true
fi
# —————————————————————————


ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#458588'

export LC_ALL="en_US.UTF-8"
export LANG="en_US.UTF-8"
export LANGUAGE="en_US.UTF-8"
export BAT_THEME="gruvbox-dark"
export PATH=$PATH:$HOME/.local/bin
export PATH=$PATH:$HOME/.spicetify

alias fastfetch="fastfetch --logo-padding-top 3 --logo-padding-left 4"
alias my-ip="ip -c -h -s addr"
alias e="eza -lbhHigaUm --git --group --group-directories-first --icons=auto --color-scale=all --colour=auto"
alias cd="z"
alias cat="bat"
alias zoom="tree -shaCL 2 --du"

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

function update() {
    # 1. System Packages (DNF)
    print -P "\n%F{green}%B==> Updating System Packages (DNF)...%b%f"
    sudo dnf upgrade --refresh || return 1

    # 2. Flatpak Applications
    print -P "\n%F{green}%B==> Updating Flatpaks...%b%f"
    flatpak update || return 1

    # 3. Rust Toolchain
    print -P "\n%F{green}%B==> Updating Rust Toolchain...%b%f"
    rustup update || return 1

    # 4. Atuin Shell History
    print -P "\n%F{green}%B==> Updating Atuin...%b%f"
    atuin update || return 1

    # 5. Cargo Binaries (Smart Update)
    # This replaces the manual 'cargo install' list for eza, dysk, etc. 
    print -P "\n%F{green}%B==> Updating Cargo Binaries...%b%f"
    cargo install-update -a

    print -P "\n%F{green}%B==> All updates complete!%b%f"
}

if [[ -s /etc/grc.zsh ]]; then
  source /etc/grc.zsh
fi

eval "$(zoxide init zsh)"

. "$HOME/.atuin/bin/env"

eval "$(atuin init zsh)"
