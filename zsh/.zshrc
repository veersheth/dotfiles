autoload -U colors && colors
setopt PROMPT_SUBST

NEWLINE=$'\n'
ZSHCOLOR="#d9bfff"
PS1="${NEWLINE} %{$fg[magenta]%}%~%{$fg[red]%} %{$reset_color%}$%b "

HISTFILE=~/.zsh_history
HISTSIZE=1500
SAVEHIST=1500
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

cdc() {
  local dir
  dir=$(find . -type d 2>/dev/null \
        | sed 's|^\./||' \
        | fzf --height=40% --reverse --prompt="cd > ") || return

  [ -n "$dir" ] && cd "$dir"
}

alias jj="~/scripts/tmux-sessionizer --init"

opengui() { xdg-open . & }
zle -N opengui
bindkey '^e' opengui
bindkey '^p' history-beginning-search-backward
bindkey '^n' history-beginning-search-forward

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
export PATH="/home/veer/.bun/bin:$PATH"

alias nxp="sudo nvim /etc/nixos/configuration.nix; sudo nixos-rebuild switch"
alias quarry="/home/veer/code/personal/quarry/src-tauri/target/release/quarry"


export PATH="/home/veer/.local/bin:$PATH"
