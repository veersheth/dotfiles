bindkey -e
autoload -U colors && colors
setopt PROMPT_SUBST

PROMPT=" %{$fg[yellow]%}%~%{$fg[blue]%}%{$reset_color%} "

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
alias l="ls -l --color=auto"
alias ls="ls --color=auto"
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
    xdg-open . &
}
zle -N opengui
bindkey '^e' opengui

autoload -U compinit && compinit
autoload -U colors && colors
zmodload zsh/complist

bindkey '^[[A' history-beginning-search-backward
alias cse="ssh -t z5494316@cse.unsw.edu.au 'cd ~/cse; exec zsh -l'"

export XDG_DATA_DIRS="$HOME/.nix-profile/share:$XDG_DATA_DIRS"
export PATH="$HOME/.nix-profile/bin:/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin:$PATH"

nixadd() {
  nix profile add "$@"
  applications_dir="$HOME/.local/share/applications"
  profile_dir="$HOME/.nix-profile"
  find "$applications_dir" -type l -lname "$profile_dir/*" -delete
  find "$profile_dir/share/applications" -name '*.desktop' | while read -r desktopfile; do
    ln -sf "$desktopfile" "$applications_dir/"
  done
  # Prefix Exec lines with nixGL
  for desktopfile in "$applications_dir"/*.desktop; do
    sed -i '/^Exec=/ s|^Exec=\(.*\)|Exec=nixGL \1|' "$desktopfile"
  done
  update-desktop-database "$applications_dir"
}
alias nixadd='nixadd'

nixremove() {
  nix profile remove "$@"
  applications_dir="$HOME/.local/share/applications"
  profile_dir="$HOME/.nix-profile"
  find "$applications_dir" -type l -lname "$profile_dir/*" -delete
  find "$profile_dir/share/applications" -name '*.desktop' | while read -r desktopfile; do
    ln -sf "$desktopfile" "$applications_dir/"
  done
  update-desktop-database "$applications_dir"
}
alias nixremove='nixremove'

alias unsw="sshfs z5494316@cse.unsw.edu.au:/import/adams/8/z5494316/cse/ ~/mnt; cd ~/mnt"
alias unswstop='fusermount -uz ~/mnt && pkill -f "sshfs.*mnt"'
alias unswreset="killall -9 sshfs; fusermount -u ~/mnt; sshfs z5494316@cse.unsw.edu.au:/import/adams/8/z5494316/cse/ ~/mnt; cd ~/mnt"
