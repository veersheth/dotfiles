autoload -U colors && colors
setopt PROMPT_SUBST

NEWLINE=$'\n'
ZSHCOLOR="#d9bfff"
# PROMPT="${NEWLINE} %{$fg[yellow]%}%~%{$fg[blue]%}%{$reset_color%}${NEWLINE} $ "
PROMPT='${NEWLINE}%F{${ZSHCOLOR}}%n@%m%f %F{#b5b5b5}%~%f${NEWLINE}%F{${ZSHCOLOR}}$ %f'

HISTFILE=~/.zsh_history
HISTSIZE=100
SAVEHIST=100
setopt INC_APPEND_HISTORY       # Add commands as they are typed
setopt SHARE_HISTORY            # Share history across terminals
setopt HIST_IGNORE_DUPS         # Ignore duplicate commands
setopt HIST_FIND_NO_DUPS        # Don't display dupes when searching history

export EDITOR="nvim"
export VISUAL="nvim"
alias vi="nvim"
alias l="ls -la --color=auto"
alias ls="ls --color=auto"
alias open="xdg-open"
alias lg="lazygit"
alias ..="cd .."
alias ...="cd ../.."

jj() {
    if ! tmux attach; then
        mkdir -p /tmp/temptmux
        tmux new-session -d -s TEMP -c /tmp/temptmux
        tmux new-session -d -s HOME -c ~
        tmux attach -t HOME
    fi
}

bindkey "^H" backward-kill-word
bindkey "^N" history-search-forward
bindkey "^P" history-search-backward
bindkey '^R' fzf-history-widget

opengui() { xdg-open . & }
zle -N opengui
bindkey '^e' opengui

autoload -U compinit && compinit
zstyle ':completion:*' menu select
zmodload zsh/complist
autoload -U colors && colors
zmodload zsh/complist

# unsw based shortcuts to mount/ssh
alias unsw="sshfs z5494316@cse.unsw.edu.au:/import/adams/8/z5494316/cse/ ~/mnt; cd ~/mnt"
alias unswstop='fusermount -uz ~/mnt && pkill -f "sshfs.*mnt" & pkill ssh'
alias unswreset="killall -9 sshfs; fusermount -u ~/mnt; sshfs z5494316@cse.unsw.edu.au:/import/adams/8/z5494316/cse/ ~/mnt; cd ~/mnt"
alias cse="ssh -t z5494316@cse.unsw.edu.au 'cd ~/cse; exec zsh -l'"

# YO PATH 
export PATH="$HOME/scripts:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
