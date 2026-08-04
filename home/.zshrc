# Keep local history out of the public repository.
HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
HISTSIZE=50000
SAVEHIST=10000

setopt append_history
setopt hist_expire_dups_first
setopt hist_ignore_all_dups
setopt hist_ignore_space
setopt share_history

# Homebrew must be available before the remaining shell tools initialize.
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

export EDITOR="cursor --wait"
export VISUAL="$EDITOR"
export DEV_HOME="$HOME/Developer"
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"

path=(
  "$HOME/.local/bin"
  "$ANDROID_HOME/emulator"
  "$ANDROID_HOME/platform-tools"
  $path
)

if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi

# Antidote installs and loads the declarative plugin list.
if [[ -r /opt/homebrew/opt/antidote/share/antidote/antidote.zsh ]]; then
  source /opt/homebrew/opt/antidote/share/antidote/antidote.zsh
  antidote load
fi

bindkey "^f" autosuggest-accept

HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1
if (( $+widgets[history-substring-search-up] )); then
  bindkey "^[[A" history-substring-search-up
  bindkey "^[[B" history-substring-search-down
else
  autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
  zle -N up-line-or-beginning-search
  zle -N down-line-or-beginning-search
  bindkey "^[[A" up-line-or-beginning-search
  bindkey "^[[B" down-line-or-beginning-search
fi

zstyle ":completion:*" matcher-list "m:{a-zA-Z}={A-Za-z}"
zstyle ":completion:*" menu no
zstyle ":completion:*:descriptions" format "[%d]"
zstyle ":fzf-tab:complete:cd:*" fzf-preview 'eza -1 --color=always $realpath'

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

alias cls="clear"
alias cdd="cd ../.."
alias dev='cd "$DEV_HOME"'
alias appzudio='cd "$DEV_HOME/appzudio"'
alias icloud='cd "$HOME/Library/Mobile Documents/com~apple~CloudDocs"'

alias ls="eza --icons=auto --group-directories-first"
alias l="eza --icons=auto --group-directories-first --git-ignore"
alias ll="eza --icons=auto --group-directories-first --all --header --long"
alias llm="eza --icons=auto --group-directories-first --all --header --long --sort=modified"
alias lt="eza --icons=auto --group-directories-first --tree"
alias tree="eza --icons=auto --group-directories-first --tree"
