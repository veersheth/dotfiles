autoload -U colors && colors
bindkey -v

new_line() { printf "\n " }
PROMPT=" $(new_line)%{$fg[yellow]%}%~%{$fg[blue]%} %{$reset_color%} $(new_line)$ "

HISTSIZE=10000
SAVEHIST=10000
source <(fzf --zsh)

export PNPM_HOME="/home/veer/.local/share/pnpm"
export EDITOR="nvim"
export VISUAL="nvim"
export MANPAGER="nvim +Man!"
alias cat="bat"
alias vi="nvim"
alias lg="lazygit"
alias ls="ls --color=auto"
alias ..="cd .."
alias ...="cd ../.."
alias open="xdg-open"

alias unsw="sshfs z5494316@cse.unsw.edu.au:/import/adams/8/z5494316/cse/ ~/mnt; cd ~/mnt"
alias unswstop='fusermount -uz ~/mnt && pkill -f "sshfs.*mnt"'
alias unswreset="killall -9 sshfs; fusermount -u ~/mnt; sshfs z5494316@cse.unsw.edu.au:/import/adams/8/z5494316/cse/ ~/mnt; cd ~/mnt"

HISTSIZE=10000
SAVEHIST=10000
source <(fzf --zsh)
