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

# Homebrew downloads with twice the number of CPU cores by default, and renders
# those parallel downloads as a live progress display that moves the cursor up,
# overwrites the previous rows, and leaves the last row without a newline. That
# display owns the bottom of the screen and assumes nothing else writes to it,
# which `brew bundle` breaks: it installs one package while it already downloads
# the next, so cask output and the `sudo` password prompt land in the middle of
# the redraw. From the first collision on, the cursor arithmetic is off by a row
# and every later line, from Homebrew and from this setup alike, is printed at
# the wrong column.
#
# Downloading in serial takes the plain, line-oriented code path instead, where
# no output can be misplaced. It costs the overlap between the download of one
# package and the installation of the previous one, which is a fair price for a
# readable log on a run that installs a fresh Mac exactly once.
export HOMEBREW_DOWNLOAD_CONCURRENCY=1

log "Installing Homebrew formulae and casks"
brew bundle --file "$REPO_ROOT/Brewfile"

log "Removing unmanaged Homebrew formulae, casks, and taps"
brew bundle cleanup \
  --force \
  --formula \
  --cask \
  --tap \
  --file "$REPO_ROOT/Brewfile"

# Homebrew 6 always quarantines cask downloads. Clear that flag from the
# apps just installed so Gatekeeper does not ask to open them again.
"${REPO_ROOT}/scripts/clear-cask-quarantine.sh"
