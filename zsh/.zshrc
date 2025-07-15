if [[ ":$FPATH:" != *":/home/veer/.zsh/completions:"* ]]; then
  export FPATH="/home/veer/.zsh/completions:$FPATH"
fi

export PATH="$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH"

export EDITOR="nvim"
export VISUAL="nvim"
export PNPM_HOME="/home/veer/.local/share/pnpm"

CASE_SENSITIVE="false"

ZSH_THEME="bureau"
plugins=(git fzf extract sudo) 
zstyle ':omz:update' mode disabled 
source "$HOME/.oh-my-zsh/oh-my-zsh.sh"

alias cat="bat"
alias vi="nvim"
alias lg="lazygit"
alias ls="ls --color=auto"
alias ll="ls -lah"
alias l="ls -CF"
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias c="clear"
alias open="xdg-open"

alias unswstart="sshfs z5494316@cse.unsw.edu.au:/import/adams/8/z5494316/cse/ ~/mnt; cd ~/mnt"
alias unswstop="fusermount -u ~/mnt"
alias unswreset="killall -9 sshfs; fusermount -u ~/mnt; sshfs z5494316@cse.unsw.edu.au:/import/adams/8/z5494316/cse/ ~/mnt; cd ~/mnt"

. "/home/veer/.deno/env"
bindkey -v
