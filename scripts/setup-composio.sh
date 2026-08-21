#!/usr/bin/env bash

# The Composio CLI has no Homebrew formula and no runtime package this setup
# will use. This script is the install channel: it runs the committed
# official installer with COMPOSIO_INSTALL_SHELL=none so ~/.zshrc stays
# untouched, then converges the native Claude Code and Codex plugins.
#
# Login stays manual. Credentials live in ~/.composio and must never land
# in this repository.

set -Eeuo pipefail

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly INSTALLER="${REPO_ROOT}/scripts/install-composio.sh"

DRY_RUN=false

usage() {
  printf 'Usage: %s [--dry-run]\n' "${0##*/}"
}

for argument in "$@"; do
  case "$argument" in
    --dry-run)
      DRY_RUN=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 64
      ;;
  esac
done

# launchd and mise hooks do not inherit an interactive shell PATH.
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
export PATH="$HOME/.local/bin:$PATH"

if [[ ! -x "$INSTALLER" ]]; then
  printf 'Committed Composio installer missing: %s\n' "$INSTALLER" >&2
  exit 1
fi

install_cli() {
  if [[ "$DRY_RUN" == true ]]; then
    if [[ -x "$HOME/.local/bin/composio" ]]; then
      printf '  + composio already present at ~/.local/bin/composio\n'
    else
      printf '  + COMPOSIO_INSTALL_SHELL=none %s\n' "$INSTALLER"
    fi
    return 0
  fi

  if [[ -x "$HOME/.local/bin/composio" ]]; then
    printf 'Composio CLI already installed at ~/.local/bin/composio\n'
    return 0
  fi

  printf 'Installing Composio CLI\n'
  COMPOSIO_INSTALL_SHELL=none "$INSTALLER"
}

configure_plugins() {
  if [[ "$DRY_RUN" == true ]]; then
    printf '  + composio setup --target auto --yes --if-present\n'
    return 0
  fi

  if ! command -v composio >/dev/null 2>&1; then
    printf 'composio was not found after installation.\n' >&2
    exit 1
  fi

  printf 'Configuring Composio agent plugins\n'
  composio setup --target auto --yes --if-present
}

install_cli
configure_plugins
