autoload -U colors && colors
setopt PROMPT_SUBST

NEWLINE=$'\n'
# PROMPT="${NEWLINE} %{$fg[yellow]%}%~%{$fg[blue]%}%{$reset_color%}${NEWLINE} $ "
PROMPT='${NEWLINE}%F{yellow}%n@%m%f %F{white}%~%f${NEWLINE}%F{yellow}$ %f'

HISTFILE=~/.zsh_history
HISTSIZE=100
SAVEHIST=100
setopt INC_APPEND_HISTORY       # Add commands as they are typed
setopt SHARE_HISTORY            # Share history across terminals
setopt HIST_IGNORE_DUPS         # Ignore duplicate commands
setopt HIST_FIND_NO_DUPS        # Don't display dupes when searching history

export PNPM_HOME="/home/veer/.local/share/pnpm"
export EDITOR="nvim"
export VISUAL="nvim"
alias vi="nvim"
alias l="ls -la --color=auto"
alias ls="ls --color=auto"
alias open="xdg-open"
alias lg="lazygit"
alias jj="tmux a || cd ~ ; tmux"

bindkey "^a" beginning-of-line
bindkey "^e" end-of-line
bindkey "^k" kill-line
bindkey "^j" backward-word
bindkey "^k" forward-word
bindkey "^H" backward-kill-word
bindkey "^N" history-search-forward
bindkey "^P" history-search-backward
bindkey '^R' fzf-history-widget

if command -v bat &> /dev/null; then;
    alias cat='bat'
elif command -v batcat &> /dev/null; then
    alias cat='batcat'
else
    alias cat='cat'
fi

opengui() {
    xdg-open . &
}
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
