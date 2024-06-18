# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="agnoster"

# Setting history length  and stuff related to it
export HISTFILESIZE=100000
export HISTSIZE=100000
export HISTFILE=~/.zsh_history
export HISTTIMEFORMAT="[%F %T] "
PROMPT_COMMAND="zsh_history -a; $PROMPT_COMMAND"
export HISTCONTROL=ignoredups

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time
zstyle ':omz:update' mode auto        # update automatically without asking

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
HIST_STAMPS="dd.mm.yyyy"

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
git
zsh-autosuggestions
zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#458588'

export LC_ALL="en_US.UTF-8"
export LANG="en_US.UTF-8"
export LANGUAGE="en_US.UTF-8"
export PATH=$HOME/.local/bin:$PATH
export PATH="$HOME/STMicroelectronics/STM32Cube/STM32CubeProgrammer/bin:$PATH"

function myTree() {
    if [ -z "$1" ]; then
        tree -LChas 1
    else
        tree -LChas "$1"
    fi
}

alias show='myTree'
alias remote-connect="ssh asimov@100.96.1.34"
alias stats-connect="ssh stats@100.96.1.34"
alias hist="history | grep"
alias my-ip="ip -c -h -s addr"
alias filter="ls -la | grep"
alias ls="ls --color=auto"
alias update="sudo dnf upgrade"
alias cd="z"
alias cat="bat"
alias tn="tmux new -s"
alias ta="tmux attach -t"
alias tl="tmux list-sessions"
alias fetch-st="rsync -avh --progress --delete \
                asimov@100.96.1.34:/home/asimov/yocto/STM32MP1-Ecosystem-v5.0.3/Distribution-Package/build-openstlinuxweston-stm32mp13-disco/tmp-glibc/deploy/images/ \
                /home/algernon/Desktop/ST/images"

eval "$(zoxide init zsh)"


# ---
# Server settings ----------------------------------------------------------------
# ---

# export LC_ALL="en_US.UTF-8"
# export LANG="en_US.UTF-8"
# export LANGUAGE="en_US.UTF-8"

# start tmux if we ssh into the box
# if [[ -n "$PS1" ]] && [[ -z "$TMUX" ]] && [[ -n "$SSH_CONNECTION" ]]; then
#     tmux attach-session -t $USER || tmux new-session -s $USER
# fi

# export PATH=$PATH:$HOME/bin
# export PATH=$PATH:$HOME/.local/bin
