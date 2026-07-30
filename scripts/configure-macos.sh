#!/usr/bin/env bash

set -Eeuo pipefail

DRY_RUN=false
readonly screenshots_directory="$HOME/Pictures/Screenshots"

if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
elif [[ "$#" -gt 0 ]]; then
  printf 'Usage: %s [--dry-run]\n' "${0##*/}" >&2
  exit 64
fi

if [[ "$(uname -s)" != "Darwin" ]]; then
  printf 'macOS configuration is available on macOS only.\n'
  exit 0
fi

# 28-31 reserve Command-Shift-3 and Command-Shift-4 variants for CleanShot.
# 64 reserves Command-Space for Raycast.
# 184 reserves Command-Shift-5 for CleanShot.
readonly shortcut_ids=(28 29 30 31 64 184)

if [[ "$DRY_RUN" == true ]]; then
  printf 'Would store macOS screenshots in %s.\n' "$screenshots_directory"
  printf 'Would disable macOS symbolic hotkeys: %s\n' "${shortcut_ids[*]}"
  exit 0
fi

mkdir -p "$screenshots_directory"
defaults write com.apple.screencapture location -string "$screenshots_directory"

readonly preferences_file="$(mktemp)"
trap 'rm -f "$preferences_file"' EXIT

if ! defaults export com.apple.symbolichotkeys "$preferences_file" >/dev/null 2>&1; then
  plutil -create xml1 "$preferences_file"
fi

for shortcut_id in "${shortcut_ids[@]}"; do
  if ! /usr/libexec/PlistBuddy -c "Print :AppleSymbolicHotKeys" "$preferences_file" >/dev/null 2>&1; then
    /usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys dict" "$preferences_file"
  fi

  if ! /usr/libexec/PlistBuddy -c "Print :AppleSymbolicHotKeys:${shortcut_id}" "$preferences_file" >/dev/null 2>&1; then
    /usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:${shortcut_id} dict" "$preferences_file"
  fi

  if /usr/libexec/PlistBuddy -c "Print :AppleSymbolicHotKeys:${shortcut_id}:enabled" "$preferences_file" >/dev/null 2>&1; then
    /usr/libexec/PlistBuddy -c "Set :AppleSymbolicHotKeys:${shortcut_id}:enabled false" "$preferences_file"
  else
    /usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:${shortcut_id}:enabled bool false" "$preferences_file"
  fi
done

defaults import com.apple.symbolichotkeys "$preferences_file" >/dev/null
killall SystemUIServer >/dev/null 2>&1 || true

printf 'Reserved macOS shortcuts for Raycast and CleanShot.\n'
printf 'Configured the macOS screenshot directory.\n'
