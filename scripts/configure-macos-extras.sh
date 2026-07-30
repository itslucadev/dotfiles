#!/usr/bin/env bash

set -Eeuo pipefail

readonly screenshots_directory="$HOME/Pictures/Screenshots"

if [[ "${1:-}" == "--dry-run" ]]; then
  printf 'Would store macOS screenshots in %s.\n' "$screenshots_directory"
  exit 0
elif [[ "$#" -gt 0 ]]; then
  printf 'Usage: %s [--dry-run]\n' "${0##*/}" >&2
  exit 64
fi

if [[ "$(uname -s)" != "Darwin" ]]; then
  printf 'Dynamic macOS preferences are available on macOS only.\n'
  exit 0
fi

mkdir -p "$screenshots_directory"
defaults write com.apple.screencapture location -string "$screenshots_directory"
killall SystemUIServer >/dev/null 2>&1 || true

printf 'Configured the macOS screenshot directory.\n'
