#!/usr/bin/env bash

set -Eeuo pipefail

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

if [[ "${1:-}" == "--dry-run" ]]; then
  printf 'Would apply %s with Homebrew Bundle.\n' "$REPO_ROOT/Brewfile.mas"
  exit 0
elif [[ "$#" -gt 0 ]]; then
  printf 'Usage: %s [--dry-run]\n' "${0##*/}" >&2
  exit 64
fi

if ! command -v brew >/dev/null 2>&1 || ! command -v mas >/dev/null 2>&1; then
  printf 'Warning: mas is unavailable, so Xcode and RocketSim were skipped.\n' >&2
  printf 'After installing mas and signing in to the App Store, run: mise run apps:mas\n'
  exit 0
fi

if brew bundle --file "$REPO_ROOT/Brewfile.mas"; then
  printf 'Mac App Store applications are installed.\n'
else
  printf 'Warning: Xcode or RocketSim could not be installed automatically.\n' >&2
  printf 'Sign in to the App Store, claim both applications if necessary, and run: mise run apps:mas\n'
fi
