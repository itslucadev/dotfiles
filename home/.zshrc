# Without these three lines there is effectively no shell history. zsh defaults
# to HISTSIZE=30, SAVEHIST=0, and an unset HISTFILE, so nothing survives a
# session. The two sizes are kept equal on purpose: HISTSIZE is the in-memory
# list and SAVEHIST is what reaches the file, so a larger HISTSIZE would only
# hold entries that can never be saved. 50000 lines cost a few megabytes and are
# what make fzf's Ctrl-R and zsh-history-substring-search worth having.
HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000

# share_history already implies append_history, and hist_ignore_all_dups keeps
# duplicates out of the list entirely, so no expiry policy is needed.
setopt hist_ignore_all_dups
setopt hist_ignore_space
setopt share_history

# Homebrew must be available before the remaining shell tools initialize.
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# bootstrap.sh installs mise here, so this directory has to be on PATH before
# mise can be found and activated below. Every other managed PATH entry and
# environment variable, including the Android SDK, comes from mise.toml.
path=(
  "$HOME/.local/bin"
  $path
)

if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

export EDITOR="cursor --wait"
export VISUAL="$EDITOR"
export DEV_HOME="$HOME/Developer"

# Every guard below matters. bootstrap.sh links this file before the Brewfile
# is applied, so the first terminal after it has neither antidote nor these
# tools yet.
if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi

# Antidote installs and loads the declarative plugin list.
if [[ -r /opt/homebrew/opt/antidote/share/antidote/antidote.zsh ]]; then
  source /opt/homebrew/opt/antidote/share/antidote/antidote.zsh
  antidote load
fi

# These key bindings need widgets that the plugins above create.
if (( $+widgets[autosuggest-accept] )); then
  bindkey "^f" autosuggest-accept
fi

HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1
if (( $+widgets[history-substring-search-up] )); then
  bindkey "^[[A" history-substring-search-up
  bindkey "^[[B" history-substring-search-down
fi

# The first three are case-insensitive completion and the grouped headers and
# menu style that fzf-tab expects. The last one previews directories with eza.
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

# `~/.claude/settings.json` already sets Auto mode as the default permission
# mode, so the flag is redundant there and deliberate here: these aliases have
# to keep starting Claude Code in Auto mode even in a directory whose project
# settings choose another default. `cc` also shadows the C compiler, which only
# affects interactive shells, because aliases never reach scripts or Makefiles.
alias cc="claude --permission-mode auto"
alias ccw="claude --permission-mode auto --worktree"

alias ls="eza --icons=auto --group-directories-first"
alias l="eza --icons=auto --group-directories-first --git-ignore"
alias ll="eza --icons=auto --group-directories-first --all --header --long"
alias llm="eza --icons=auto --group-directories-first --all --header --long --sort=modified"
alias lt="eza --icons=auto --group-directories-first --tree"
