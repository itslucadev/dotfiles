#!/usr/bin/env bash

# The Homebrew stage of the managed setup, run as the `pre-dotfiles` bootstrap
# hook in mise.toml.
#
# Homebrew stays outside `[bootstrap.packages]` on purpose. mise converges
# forward only and never removes a package that the configuration stopped
# declaring, while `brew bundle cleanup` does exactly that. Keeping the Brewfile
# preserves the removal pass, the third-party taps, and the cask options.

set -Eeuo pipefail

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "${REPO_ROOT}/scripts/lib.sh"

if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

if ! command -v brew >/dev/null 2>&1; then
  printf 'brew is missing. Run ./bootstrap.sh first.\n' >&2
  exit 1
fi

log "Installing Homebrew formulae and casks"
brew bundle --file "$REPO_ROOT/Brewfile"

log "Removing unmanaged Homebrew formulae, casks, and taps"
brew bundle cleanup \
  --force \
  --formula \
  --cask \
  --tap \
  --file "$REPO_ROOT/Brewfile"
