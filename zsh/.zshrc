export PATH="$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH"
CASE_SENSITIVE="false"
plugins=( git fzf extract sudo)

export EDITOR="nvim"
export VISUAL="nvim"
alias vi="nvim"
alias lg="lazygit"
alias ls="ls --color=auto"
alias ll="ls -lah"
alias l="ls -CF"
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

export PNPM_HOME="/home/veer/.local/share/pnpm"
ZSH_THEME="bureau"

zstyle ':omz:update' mode disabled  # disable automatic updates
plugins=(git)
source "$HOME/.oh-my-zsh/oh-my-zsh.sh"
