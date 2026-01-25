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
alias update="sudo dnf upgrade --refresh && flatpak update && rustup update && cargo install tock eza pueue dysk yazi-build ripgrep"
alias cd="z"
alias cat="bat"
alias conn-server="ssh asimov@macondo"
alias zoom="tree -shaCL 2 --du"

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

if [[ -s /etc/grc.zsh ]]; then
  source /etc/grc.zsh
fi

eval "$(zoxide init zsh)"

. "$HOME/.atuin/bin/env"

eval "$(atuin init zsh)"
