# === History ===
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

# === Homebrew, PATH, and tool activation ===
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

# === Secrets ===
# fnox resolves secrets through Doppler, whose auth token lives in the login
# keychain. SSH sessions start with a locked keychain, so activating fnox there
# only produces resolver warnings. Secrets stay reachable over SSH on demand
# with `fnox get` or `fnox exec` after `security unlock-keychain`.
if [[ -z "$SSH_CONNECTION" ]] && command -v fnox >/dev/null 2>&1; then
  eval "$(fnox activate zsh)"
fi

# === Environment ===
# --wait keeps the CLI open until the file closes; without it, callers like
# `git commit` see the editor exit immediately and read an empty message.
export EDITOR="code --wait"
export VISUAL="$EDITOR"
export DEV_HOME="$HOME/Developer"

# === Plugins and key bindings ===
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

# === Completion styling ===
# The first three are case-insensitive completion and the grouped headers and
# menu style that fzf-tab expects. The last one previews directories with eza.
zstyle ":completion:*" matcher-list "m:{a-zA-Z}={A-Za-z}"
zstyle ":completion:*" menu no
zstyle ":completion:*:descriptions" format "[%d]"
zstyle ":fzf-tab:complete:cd:*" fzf-preview 'eza -1 --color=always $realpath'

# === Prompt and navigation ===
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# === Aliases ===
alias cls="clear"
alias cdd="cd ../.."
alias dev='cd "$DEV_HOME"'
alias appzudio='cd "$DEV_HOME/appzudio"'
alias dotfiles='cd "$HOME/github/phoenix-error/dotfiles"'
alias icloud='cd "$HOME/Library/Mobile Documents/com~apple~CloudDocs"'

# `~/.claude/settings.json` already sets Auto mode as the default permission
# mode, so the flag is redundant there and deliberate here: these aliases have
# to keep starting Claude Code in Auto mode even in a directory whose project
# settings choose another default. `cc` also shadows the C compiler, which only
# affects interactive shells, because aliases never reach scripts or Makefiles.
alias cc="claude --permission-mode auto"
alias ccw="claude --permission-mode auto --worktree"
# gh resolves a bare repository name against the authenticated account, so this
# takes just the name for own repos and still accepts owner/repo for everything
# else. Trailing git flags need the -- separator, as in `clone foo -- --depth=1`.
alias clone="gh repo clone"

# eza replaces ls, so these stay guarded: an unguarded alias would break plain
# `ls` in the first terminal after bootstrap. The other aliases wrap commands
# that fail identically with or without the alias, so they need no guard.
if command -v eza >/dev/null 2>&1; then
  alias ls="eza --icons=auto --group-directories-first"
  alias l="eza --icons=auto --group-directories-first --git-ignore"
  alias ll="eza --icons=auto --group-directories-first --all --header --long"
  alias llm="eza --icons=auto --group-directories-first --all --header --long --sort=modified"
  alias lt="eza --icons=auto --group-directories-first --tree"
fi

alias mbp="ssh lucabecker@mbp"
alias nas="ssh phoenix-error@nas"
