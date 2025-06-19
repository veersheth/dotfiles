# Add deno completions to search path
if [[ ":$FPATH:" != *":/home/veer/.zsh/completions:"* ]]; then export FPATH="/home/veer/.zsh/completions:$FPATH"; fi
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
alias c="clear"

bindkey '^H' backward-kill-word
bindkey '5~' kill-word

export PNPM_HOME="/home/veer/.local/share/pnpm"
ZSH_THEME="bureau"

zstyle ':omz:update' mode disabled  # disable automatic updates
plugins=(git)
source "$HOME/.oh-my-zsh/oh-my-zsh.sh"

alias open="xdg-open"
alias unswmnt="sshfs z5494316@cse.unsw.edu.au:/import/adams/8/z5494316/cse/ ~/mnt"
alias unswunmnt="fusermount -u ~/mnt"
. "/home/veer/.deno/env"
# Initialize zsh completions (added by deno install script)
autoload -Uz compinit
compinit