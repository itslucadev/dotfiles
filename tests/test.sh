#!/usr/bin/env bash

set -Eeuo pipefail

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

export HOMEBREW_NO_AUTO_UPDATE=1

cd "$REPO_ROOT"

printf 'Checking shell syntax\n'
while IFS= read -r script; do
  bash -n "$script"
done < <(find . -path './.git' -prune -o -path './.worktrees' -prune -o -name '*.sh' -type f -print)
zsh -n home/.zprofile
zsh -n home/.zshrc

printf 'Checking TOML syntax\n'
toml_checked=false
for python_command in python3.14 python3.13 python3.12 python3.11 python3; do
  if command -v "$python_command" >/dev/null 2>&1 &&
    "$python_command" -c 'import tomllib' >/dev/null 2>&1; then
    "$python_command" - <<'PY'
from pathlib import Path
import tomllib

for path in sorted(Path(".").glob("*.toml")):
    with path.open("rb") as file:
        tomllib.load(file)
PY
    toml_checked=true
    break
  fi
done

if [[ "$toml_checked" != true ]] && command -v mise >/dev/null 2>&1; then
  MISE_SAFE=1 mise config ls >/dev/null
  toml_checked=true
fi

if [[ "$toml_checked" != true ]]; then
  printf 'No TOML parser is available.\n' >&2
  exit 1
fi

printf 'Checking Brewfiles\n'
if command -v brew >/dev/null 2>&1; then
  brew bundle list --file Brewfile >/dev/null
  brew bundle list --file Brewfile.mas >/dev/null
fi

printf 'Checking executable files\n'
for executable in \
  apply.sh \
  bootstrap.sh \
  scripts/configure-macos.sh \
  scripts/doctor.sh \
  scripts/install-editor-extensions.sh \
  scripts/install-raycast-beta.sh \
  tests/test.sh; do
  [[ -x "$executable" ]]
done

printf 'Checking managed configuration files\n'
for managed_file in \
  home/.claude/settings.json \
  home/.claude/statusline.ts \
  home/.config/editors/extensions.txt \
  home/.config/editors/cursor/extensions.txt \
  home/.config/editors/cursor/settings.json \
  home/.config/editors/vscode/extensions.txt \
  home/.config/editors/vscode/settings.json \
  home/.config/git/ignore \
  home/.config/ghostty/config.ghostty \
  home/.config/herdr/config.toml \
  home/.config/nvim/init.lua \
  home/.config/starship.toml \
  home/.config/wezterm/wezterm.lua \
  home/.gitconfig \
  home/.ssh/config \
  home/AGENTS.md \
  home/.zprofile \
  home/.zsh_plugins.txt \
  home/.zshrc; do
  [[ -f "$managed_file" ]]
done

printf 'Checking JSON syntax\n'
if command -v jq >/dev/null 2>&1; then
  jq empty home/.claude/settings.json
  jq empty home/.config/editors/cursor/settings.json
  jq empty home/.config/editors/vscode/settings.json
else
  "$python_command" -m json.tool home/.claude/settings.json >/dev/null
  "$python_command" -m json.tool home/.config/editors/cursor/settings.json >/dev/null
  "$python_command" -m json.tool home/.config/editors/vscode/settings.json >/dev/null
fi

if command -v bun >/dev/null 2>&1; then
  typescript_output="$(mktemp)"
  bun build home/.claude/statusline.ts \
    --target=bun \
    --outfile="$typescript_output" \
    >/dev/null
  rm -f "$typescript_output"
fi

if command -v nvim >/dev/null 2>&1; then
  while IFS= read -r lua_file; do
    nvim --clean --headless -i NONE \
      -c "lua assert(loadfile([[${lua_file}]]))" \
      -c "quit"
  done < <(find home/.config/nvim -type f -name "*.lua" -print)
fi

printf 'Checking dry-run paths\n'
./bootstrap.sh --dry-run >/dev/null
./apply.sh --dry-run >/dev/null
./scripts/configure-macos.sh --dry-run >/dev/null
./scripts/install-editor-extensions.sh --dry-run >/dev/null
./scripts/install-raycast-beta.sh --dry-run >/dev/null

printf 'Checking excluded tools and applications\n'
for forbidden in \
  '"npm:@higgsfield/cli"' \
  '"npm:firecrawl-cli"' \
  '"npm:@openai/codex"' \
  '"npm:@withgraphite/graphite-cli"' \
  '"npm:portless"' \
  '"npm:snapai"' \
  'brew "graphite"' \
  'brew "graphite-cli"' \
  'brew "yt-dlp"' \
  'cask "keepingyouawake"' \
  'cask "parsec"' \
  'cask "stats"' \
  'cask "zed"' \
  'cask "xcode-beta"'; do
  if grep -Fq "$forbidden" mise.toml Brewfile Brewfile.mas; then
    printf 'Forbidden setup entry found: %s\n' "$forbidden" >&2
    exit 1
  fi
done

printf 'Checking editor ownership\n'
grep -Fq 'cask "cursor"' Brewfile
grep -Fq 'cask "visual-studio-code"' Brewfile
grep -Fq '"~/Library/Application Support/Code/User/settings.json" = { source = "home/.config/editors/vscode/settings.json" }' mise.toml
grep -Fq '"~/Library/Application Support/Cursor/User/settings.json" = { source = "home/.config/editors/cursor/settings.json" }' mise.toml

for editor in cursor vscode; do
  grep -Fq '"workbench.colorTheme": "Rosé Pine Moon"' \
    "home/.config/editors/${editor}/settings.json"
  grep -Fq '"editor.fontFamily": "Hack Nerd Font Mono"' \
    "home/.config/editors/${editor}/settings.json"
done

grep -Fq 'mvllow.rose-pine' home/.config/editors/extensions.txt

printf 'Checking Python and React editor setup\n'
for runtime in \
  'python = "3.12"' \
  'uv = "latest"' \
  'ruff = "latest"' \
  '"npm:@biomejs/biome" = "latest"' \
  '"npm:prettier" = "latest"'; do
  grep -Fq "$runtime" mise.toml
done

grep -Fq 'UV_PYTHON = { value = "{{ tools.python.path }}", tools = true }' mise.toml

if grep -Eq 'brew "(python(@3\.12)?|uv|ruff|biome|prettier)"' Brewfile; then
  printf 'Python and formatter tooling must be managed by mise, not Homebrew.\n' >&2
  exit 1
fi

if grep -Eq '^vscode ' Brewfile; then
  printf 'Editor extensions must use the shared cross-editor installer.\n' >&2
  exit 1
fi

grep -Fq -- '--list-extensions' scripts/install-editor-extensions.sh
grep -Fq 'Already installed for %s: %s' scripts/install-editor-extensions.sh

for extension in \
  'biomejs.biome' \
  'bradlc.vscode-tailwindcss' \
  'charliermarsh.ruff' \
  'dbaeumer.vscode-eslint' \
  'esbenp.prettier-vscode' \
  'expo.vscode-expo-tools' \
  'yoavbls.pretty-ts-errors'; do
  grep -Fq "$extension" home/.config/editors/extensions.txt
done

for editor in cursor vscode; do
  if ! LC_ALL=C sort -c "home/.config/editors/${editor}/extensions.txt" ||
    [[ -n "$(sort \
      home/.config/editors/extensions.txt \
      "home/.config/editors/${editor}/extensions.txt" | uniq -d)" ]]; then
    printf '%s extension inventories must be sorted and non-overlapping.\n' "$editor" >&2
    exit 1
  fi
done

LC_ALL=C sort -c home/.config/editors/extensions.txt

for settings_file in \
  home/.config/editors/cursor/settings.json \
  home/.config/editors/vscode/settings.json; do
  grep -Fq '"editor.defaultFormatter": "charliermarsh.ruff"' "$settings_file"
  grep -Fq '"editor.defaultFormatter": "biomejs.biome"' "$settings_file"
  grep -Fq '"editor.defaultFormatter": "esbenp.prettier-vscode"' "$settings_file"
  grep -Fq '"source.fixAll.ruff": "explicit"' "$settings_file"
  grep -Fq '"source.organizeImports.ruff": "explicit"' "$settings_file"
  grep -Fq '"python-envs.alwaysUseUv": true' "$settings_file"
done

if grep -RFqi 'graphite' home/.config/editors; then
  printf 'Graphite must not be part of the managed editor setup.\n' >&2
  exit 1
fi

printf 'Checking Git and SSH ownership\n'
grep -Fq '"~/.gitconfig" = {}' mise.toml
grep -Fq '"~/.config/git/ignore" = {}' mise.toml
grep -Fq '"~/.ssh/config" = {}' mise.toml
grep -Fq 'path = ~/.gitconfig.local' home/.gitconfig
grep -Fq 'Include ~/.ssh/config.local' home/.ssh/config

if grep -Eqi 'gpgsign[[:space:]]*=[[:space:]]*true' home/.gitconfig; then
  printf 'Commit signing must be enabled only after local key setup.\n' >&2
  exit 1
fi

if grep -Eqi 'user[[:space:]]*=[[:space:]]*|email[[:space:]]*=' home/.gitconfig; then
  printf 'Public Git config must not contain personal identity.\n' >&2
  exit 1
fi

printf 'Checking Ghostty and Herdr ownership\n'
grep -Fq 'cask "ghostty"' Brewfile
grep -Fq 'brew "herdr"' Brewfile
grep -Fq '"~/.config/ghostty" = {}' mise.toml
grep -Fq '"~/.config/herdr/config.toml" = {}' mise.toml

for ghostty_setting in \
  'theme = Rose Pine Moon' \
  'font-family = Hack Nerd Font' \
  'background-opacity = 0.8' \
  'background-blur = 50'; do
  grep -Fq "$ghostty_setting" home/.config/ghostty/config.ghostty
done

ghostty_command=""
if command -v ghostty >/dev/null 2>&1; then
  ghostty_command="$(command -v ghostty)"
elif [[ -x /Applications/Ghostty.app/Contents/MacOS/ghostty ]]; then
  ghostty_command="/Applications/Ghostty.app/Contents/MacOS/ghostty"
fi

if [[ -n "$ghostty_command" ]]; then
  XDG_CONFIG_HOME="$REPO_ROOT/home/.config" \
    "$ghostty_command" +show-config >/dev/null
fi

if grep -Eq '^\[keys(\.|\])' home/.config/herdr/config.toml; then
  printf 'Herdr keybindings must use its defaults, not managed overrides.\n' >&2
  exit 1
fi

grep -Fq 'name = "rose-pine"' home/.config/herdr/config.toml
grep -Fq 'panel_bg = "reset"' home/.config/herdr/config.toml
grep -Fq 'surface_dim = "#232136"' home/.config/herdr/config.toml
grep -Fq 'blue = "#3e8fb0"' home/.config/herdr/config.toml
grep -Fq 'peach = "#ea9a97"' home/.config/herdr/config.toml

if command -v herdr >/dev/null 2>&1; then
  HERDR_CONFIG_PATH="$REPO_ROOT/home/.config/herdr/config.toml" \
    herdr config check >/dev/null
fi

printf 'Checking Zsh plugin ownership\n'
if grep -En 'brew "(zsh-autosuggestions|zsh-syntax-highlighting|zsh-history-substring-search|zsh-autopair|fzf-tab|forgit)"' Brewfile; then
  printf 'Zsh plugins must be managed by Antidote, not Homebrew.\n' >&2
  exit 1
fi

for required_plugin in \
  "Aloxaf/fzf-tab" \
  "hlissner/zsh-autopair" \
  "zsh-users/zsh-autosuggestions" \
  "zsh-users/zsh-history-substring-search" \
  "zsh-users/zsh-syntax-highlighting"; do
  if ! grep -Fq "$required_plugin" home/.zsh_plugins.txt; then
    printf 'Required Antidote plugin missing: %s\n' "$required_plugin" >&2
    exit 1
  fi
done

printf 'Checking Neovim plugin ownership\n'
if ! grep -Fq 'require("lazy").setup("plugins")' home/.config/nvim/lua/plugin.lua; then
  printf 'Lazy.nvim must own the Neovim plugin inventory.\n' >&2
  exit 1
fi

printf 'Checking global agent mappings\n'
for agent_target in \
  '"~/AGENTS.md" = { source = "home/AGENTS.md" }' \
  '"~/.agents/AGENTS.md" = { source = "home/AGENTS.md" }' \
  '"~/.claude/CLAUDE.md" = { source = "home/AGENTS.md" }'; do
  if ! grep -Fq "$agent_target" mise.toml; then
    printf 'Global agent mapping missing: %s\n' "$agent_target" >&2
    exit 1
  fi
done

if grep -Eqi 'opencode|codex' mise.toml mise.lock Brewfile; then
  printf 'OpenCode and Codex must not be part of the managed setup.\n' >&2
  exit 1
fi

printf 'Checking managed agent CLIs\n'
for agent_package in '"npm:@anthropic-ai/claude-code"'; do
  if ! grep -Fq "$agent_package" mise.toml; then
    printf 'Managed agent CLI missing: %s\n' "$agent_package" >&2
    exit 1
  fi
done

printf 'Checking Homebrew trust ownership\n'
if [[ -e home/.homebrew/trust.json ]]; then
  printf 'Generated Homebrew trust state must not be tracked.\n' >&2
  exit 1
fi

git check-ignore --quiet home/.homebrew/trust.json
grep -Fq '"~/.homebrew/Brewfile" = { source = "Brewfile" }' mise.toml

if grep -REn 'HOMEBREW_NO_REQUIRE_TAP_TRUST' \
  --exclude-dir=.git \
  --exclude='test.sh' \
  .; then
  printf 'Homebrew tap trust must not be disabled.\n' >&2
  exit 1
fi

printf 'Checking mise bootstrap configuration\n'
if grep -Eq '^dotfiles\.root = "\{\{' mise.toml ||
  grep -E '^"com\.apple\.screencapture".*\{\{' mise.toml; then
  printf 'mise does not render templates in these bootstrap fields.\n' >&2
  exit 1
fi

grep -Fq 'defaults write com.apple.screencapture location' \
  scripts/configure-macos.sh

mise_command="${MISE_BIN:-}"
if [[ -z "$mise_command" ]] && command -v mise >/dev/null 2>&1; then
  mise_command="$(command -v mise)"
fi

if [[ -n "$mise_command" ]]; then
  CI=1 "$mise_command" tasks ls >/dev/null

  validation_home="$(mktemp -d)"
  validation_status="$(mktemp)"
  trap 'rm -rf "$validation_home"; rm -f "$validation_status"' EXIT
  mkdir -p "$validation_home/github/phoenix-error"
  ln -s "$REPO_ROOT" "$validation_home/github/phoenix-error/dotfiles"

  HOME="$validation_home" CI=1 "$mise_command" \
    bootstrap dotfiles status >"$validation_status"

  if grep -Fq 'source missing' "$validation_status"; then
    printf 'mise reports a missing dotfile source.\n' >&2
    cat "$validation_status" >&2
    exit 1
  fi
else
  printf 'SKIP  mise executable is unavailable\n'
fi

printf 'Checking Raycast signing identity\n'
grep -Fq 'EXPECTED_TEAM_ID="SY64MV22J9"' scripts/install-raycast-beta.sh

printf 'Checking destructive package-manager operations\n'
if grep -REn 'brew bundle cleanup|brew uninstall|mise prune' \
  --exclude-dir=.git \
  --exclude='*.md' \
  --exclude='test.sh' \
  .; then
  printf 'Destructive package-manager operation found.\n' >&2
  exit 1
fi

printf 'Checking common secret patterns\n'
if grep -REn \
  -e '-----BEGIN ([A-Z ]+ )?PRIVATE KEY-----|AKIA[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9_]{20,}|sk-[A-Za-z0-9]{20,}' \
  --exclude-dir=.git \
  --exclude='test.sh' \
  .; then
  printf 'Possible committed secret found.\n' >&2
  exit 1
fi

printf 'Checking typography policy\n'
if grep -RFn \
  -e $'\u2014' \
  --exclude-dir=.git \
  --exclude='test.sh' \
  .; then
  printf 'Em dash found. Use a plain hyphen instead.\n' >&2
  exit 1
fi

printf 'Checking repository whitespace\n'
git diff --check

printf 'All repository tests passed.\n'
