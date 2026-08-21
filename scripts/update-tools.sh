#!/usr/bin/env bash

# The daily tool updater. The launchd agent that scripts/setup-autoupdate.sh
# installs runs this every morning, and `mise run update:tools` runs it by
# hand. It upgrades what is already installed and never touches the inventory:
# installing and removing stays with `mise run setup`, so this can never fight
# the Brewfile or `brew bundle cleanup`.
#
# Each stage is isolated. An unattended run must not lose the mise upgrades
# because one cask failed, so a failing stage is reported and counted instead
# of aborting the script, and the run exits non-zero when any stage failed.

set -Eeuo pipefail

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "${REPO_ROOT}/scripts/lib.sh"

# launchd starts this with a minimal environment, so the PATH that an
# interactive shell gets from ~/.zprofile and ~/.zshrc is rebuilt here:
# Homebrew's shell environment first, then the self-managed mise binary.
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
export PATH="$HOME/.local/bin:$PATH"

printf '\n===== Tool update run: %s =====\n' "$(date '+%Y-%m-%d %H:%M:%S')"

failed_stages=0

stage() {
  local title="$1"
  shift
  log "$title"
  if ! "$@"; then
    printf 'Stage failed: %s\n' "$title" >&2
    failed_stages=$((failed_stages + 1))
  fi
}

stage "Updating Homebrew" brew update
stage "Upgrading Homebrew formulae" brew upgrade --formula
# Casks are upgraded without --greedy on purpose. A cask marked auto_updates
# has an application updater of its own, which the managed macOS defaults in
# mise.toml switch to silent automatic installs, so Homebrew only needs to
# cover the casks that cannot update themselves. That set includes the coding
# agent casks, whose binaries never self-update in the Homebrew layout.
#
# A cask that installs through a pkg runs `sudo installer`. An interactive run
# has a terminal to answer the password prompt, so it upgrades everything. The
# unattended launchd run does not, so it skips those casks and names them in
# the log; BasicTeX is the only such cask today and updates about once a year.
upgrade_casks() {
  local outdated sudo_casks user_casks
  outdated="$(brew outdated --cask --quiet)"
  if [[ -z "$outdated" ]]; then
    printf 'Every Homebrew-updated cask is current.\n'
    return 0
  fi
  if [[ -t 0 ]]; then
    # shellcheck disable=SC2086
    brew upgrade --cask $outdated
    return
  fi
  # shellcheck disable=SC2086
  sudo_casks="$(brew info --cask --json=v2 $outdated |
    jq -r '.casks[] | select([.artifacts[] | keys[]] | any(. == "pkg" or . == "installer")) | .token')"
  user_casks="$(comm -23 <(sort <<<"$outdated") <(sort <<<"$sudo_casks"))"
  if [[ -n "$sudo_casks" ]]; then
    printf 'Needs an interactive `mise run update:tools` for sudo: %s\n' \
      "${sudo_casks//$'\n'/ }"
  fi
  if [[ -n "$user_casks" ]]; then
    # shellcheck disable=SC2086
    brew upgrade --cask $user_casks
  fi
}

stage "Upgrading Homebrew casks" upgrade_casks
# Sparkle-updated casks never go through `brew upgrade --cask`, but their
# own updater still leaves a fresh quarantine flag. Run this every morning
# even when Homebrew had nothing to upgrade.
stage "Clearing Gatekeeper quarantine from cask apps" \
  "${REPO_ROOT}/scripts/clear-cask-quarantine.sh"

stage "Pruning the Homebrew cache" brew cleanup --prune=7

if command -v mas >/dev/null 2>&1; then
  stage "Upgrading Mac App Store applications" mas upgrade
fi

stage "Updating mise" mise self-update --yes
stage "Upgrading mise tools" mise upgrade

if command -v composio >/dev/null 2>&1; then
  stage "Upgrading Composio CLI" composio upgrade
fi

if [[ "$failed_stages" -gt 0 ]]; then
  printf '\n%d stage(s) failed.\n' "$failed_stages" >&2
  exit 1
fi

printf '\nAll tools are up to date.\n'
