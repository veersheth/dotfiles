# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash, you might have to change your $PATH
export PATH="$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH"

# Oh My Zsh installation path
export ZSH="$HOME/.oh-my-zsh"

# Set Powerlevel10k as the theme (Install with `git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$ZSH/custom}/themes/powerlevel10k`)
ZSH_THEME="powerlevel10k/powerlevel10k"

# Enable Powerlevel10k instant prompt (if installed)
[[ ! -r ~/.p10k.zsh ]] || source ~/.p10k.zsh

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

# Faster auto-update frequency (every 7 days)
zstyle ':omz:update' frequency 7

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

source $ZSH/oh-my-zsh.sh

# Preferred text editor
export EDITOR="nvim"
export VISUAL="nvim"

# Use `batcat` instead of `cat`
alias cat="batcat"

# Neovim aliases
alias vi="nvim"
alias nv="nvim"

# Color-enhanced ls and tree commands
alias ls="ls --color=auto"
alias ll="ls -lah"
alias la="ls -A"
alias l="ls -CF"

# Improved navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

# Extract compressed files quickly
alias x="extract"

# Simpler clear command
alias cls="clear"

# Quick access to Zsh config
alias zshconfig="nvim ~/.zshrc"
alias ohmyzsh="nvim ~/.oh-my-zsh"

# Fix accidental sudo typos
alias please="sudo !!"

# Enable fzf key bindings and fuzzy searching (install fzf if needed)
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh

# Keybindings
bindkey '^H' backward-kill-word    # Ctrl+H to delete a whole word
bindkey '^R' history-incremental-search-backward  # Ctrl+R for searching history

# User-defined PATH (ensure pipx is properly set)
export PATH="$HOME/.local/bin:$PATH"
