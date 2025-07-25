autoload -U colors && colors
bindkey -e

PROMPT="%{$fg[yellow]%}%~%{$fg[blue]%} %{$reset_color%}"

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
alias ls="ls --color=auto"
alias ll="ls -l --color=auto"
alias ..="cd .."
alias ...="cd ../.."
alias open="xdg-open"
alias lg="lazygit"

if command -v bat &> /dev/null; then
    alias cat='bat'
elif command -v batcat &> /dev/null; then
    alias cat='batcat'
else
    alias cat='cat'
fi

opengui() {
    xdg-open .
}
zle -N opengui
bindkey '^e' opengui

autoload -U compinit && compinit
autoload -U colors && colors
zmodload zsh/complist

bindkey '^[[A' history-beginning-search-backward
bindkey -s ^f "~/scripts/tmux-sessionizer\n"
