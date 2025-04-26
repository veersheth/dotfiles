# If you come from bash, you might have to change your $PATH
export PATH="$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH"
#
# Enable case-insensitive completion
CASE_SENSITIVE="false"

# Enable hyphen-insensitive completion (`-` and `_` are interchangeable)
HYPHEN_INSENSITIVE="true"

# Enable command auto-correction
ENABLE_CORRECTION="true"

# Show red dots while waiting for completion
COMPLETION_WAITING_DOTS="%F{yellow}...%f"

# Enable faster repository status checks for large repos
DISABLE_UNTRACKED_FILES_DIRTY="true"

# Set history timestamp format
HIST_STAMPS="yyyy-mm-dd"

# Plugins for better usability (Install missing ones with `git clone`)
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-completions
  fzf
  extract
  sudo
)

# Preferred text editor
export EDITOR="nvim"
export VISUAL="nvim"

# alias cat="batcat"

alias vi="nvim"
alias nv="nvim"
alias lg="lazygit"

# Color-enhanced ls and tree commands
alias ls="ls --color=auto"
alias ll="ls -lah"
alias la="ls -A"
alias l="ls -CF"

# Improved navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

# Simpler clear command
alias cls="clear"

# Quick access to Zsh config
alias zshconfig="nvim ~/.zshrc"

# Fix accidental sudo typos
alias please="sudo !!"

# Enable fzf key bindings and fuzzy searching (install fzf if needed)
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh

# Keybindings
bindkey '^R' history-incremental-search-backward  # Ctrl+R for searching history

# User-defined PATH (ensure pipx is properly set)
export PATH="$HOME/.local/bin:$PATH"
eval "$(starship init zsh)"
