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
  scripts/configure-macos-extras.sh \
  scripts/configure-shortcuts.sh \
  scripts/doctor.sh \
  scripts/install-mas-apps.sh \
  scripts/install-raycast-beta.sh \
  tests/test.sh; do
  [[ -x "$executable" ]]
done

printf 'Checking managed configuration files\n'
for managed_file in \
  home/.config/starship.toml \
  home/.config/wezterm/wezterm.lua \
  home/.zprofile \
  home/.zsh_plugins.txt \
  home/.zshrc; do
  [[ -f "$managed_file" ]]
done

printf 'Checking dry-run paths\n'
./bootstrap.sh --dry-run >/dev/null
./apply.sh --dry-run >/dev/null
./scripts/configure-macos-extras.sh --dry-run >/dev/null
./scripts/configure-shortcuts.sh --dry-run >/dev/null
./scripts/install-mas-apps.sh --dry-run >/dev/null
./scripts/install-raycast-beta.sh --dry-run >/dev/null

printf 'Checking excluded tools and applications\n'
for forbidden in \
  '"npm:@higgsfield/cli"' \
  '"npm:firecrawl-cli"' \
  '"npm:portless"' \
  '"npm:snapai"' \
  'cask "ghostty"' \
  'cask "keepingyouawake"' \
  'cask "parsec"' \
  'cask "stats"' \
  'cask "xcode-beta"'; do
  if grep -Fq "$forbidden" mise.toml Brewfile Brewfile.mas; then
    printf 'Forbidden setup entry found: %s\n' "$forbidden" >&2
    exit 1
  fi
done

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
