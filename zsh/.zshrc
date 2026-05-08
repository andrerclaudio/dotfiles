# ——————————————————————————————————————————————————————————————————————
# 1. PATHS & ENVIRONMENT
# ——————————————————————————————————————————————————————————————————————
export ZSH="$HOME/.oh-my-zsh"
export LC_ALL="en_US.UTF-8"
export LANG="en_US.UTF-8"
export LANGUAGE="en_US.UTF-8"
export BAT_THEME="gruvbox-dark"
export PATH=$PATH:$HOME/.local/bin
export PATH=$PATH:$HOME/.spicetify

# ——————————————————————————————————————————————————————————————————————
# 2. OH-MY-ZSH CONFIGURATION
ZSH_THEME="agnoster"
zstyle ':omz:update' mode auto
HIST_STAMPS="dd.mm.yyyy"

plugins=(
  git
  autoupdate
  zsh-autocomplete
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# ——————————————————————————————————————————————————————————————————————
# 3. HISTORY SETTINGS
# ——————————————————————————————————————————————————————————————————————
export HISTFILESIZE=10000000
export HISTSIZE=999999
export HISTFILE=~/.zsh_history
export HISTTIMEFORMAT="[%F %T] "
PROMPT_COMMAND="zsh_history -a; $PROMPT_COMMAND"
export HISTCONTROL=ignoredups

# ——————————————————————————————————————————————————————————————————————
# 4. ALIASES & FUNCTIONS
# ——————————————————————————————————————————————————————————————————————
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
    print -P "\n%F{green}%B==> Updating System Packages (DNF)...%b%f"
    sudo dnf upgrade --refresh || return 1

    print -P "\n%F{green}%B==> Updating Flatpaks...%b%f"
    flatpak update || return 1

    print -P "\n%F{green}%B==> Updating Rust Toolchain...%b%f"
    rustup update || return 1

    # print -P "\n%F{green}%B==> Updating Atuin...%b%f"
    # atuin update || return 1

    print -P "\n%F{green}%B==> Updating Cargo Binaries...%b%f"
    cargo install-update -a

    print -P "\n%F{green}%B==> All updates complete!%b%f"
}

# ——————————————————————————————————————————————————————————————————————
# 5. INITIALIZATIONS & TOOLS
# ——————————————————————————————————————————————————————————————————————
# Run dysk once at terminal startup
if [[ -o interactive && $SHLVL -eq 1 ]]; then
  dysk -c label+default || true
fi

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#458588'

if [[ -s /etc/grc.zsh ]]; then
  source /etc/grc.zsh
fi

eval "$(zoxide init zsh)"

# . "$HOME/.atuin/bin/env"
# eval "$(atuin init zsh)"
