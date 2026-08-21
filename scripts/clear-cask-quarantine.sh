#!/usr/bin/env bash

# Drop Gatekeeper quarantine from Homebrew-installed cask applications.
#
# Homebrew 6 removed `--no-quarantine`. Every cask download still receives
# the `com.apple.quarantine` extended attribute, and macOS then asks
# "Are you sure you want to open it?" for that copy. Nested helpers inherit
# the same flag, which is why ChatGPT's bundled Codex Computer Use.app asks
# again after each Homebrew or Sparkle update.
#
# This is not TCC and does not touch the privacy database. It only removes
# an extended attribute from apps this machine already installed through
# the managed Brewfile. Manually downloaded applications stay untouched.

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

if ! command -v jq >/dev/null 2>&1; then
  printf 'jq is missing. Apply Brewfile first.\n' >&2
  exit 1
fi

list_cask_apps() {
  brew info --json=v2 --installed --cask | jq -r '
    .casks[].artifacts[]
    | objects
    | select(has("app"))
    | .target
      // (
        (.app | if type == "array" then .[0] else . end)
        | if type == "string" and startswith("/") then .
          elif type == "string" then "/Applications/\(.)"
          else empty
          end
      )
  '
}

if [[ "${1:-}" == "--list" ]]; then
  list_cask_apps
  exit 0
fi

if [[ $# -gt 0 ]]; then
  printf 'Usage: %s [--list]\n' "${0##*/}" >&2
  exit 64
fi

log "Clearing Gatekeeper quarantine from Homebrew cask apps"

cleared=0
clean=0
missing=0
failed=0

while IFS= read -r app; do
  [[ -n "$app" ]] || continue

  if [[ ! -e "$app" ]]; then
    printf 'Missing cask app: %s\n' "$app" >&2
    missing=$((missing + 1))
    continue
  fi

  had_quarantine=false
  if xattr -p com.apple.quarantine "$app" >/dev/null 2>&1; then
    had_quarantine=true
  fi

  # `xattr -d` exits non-zero when the attribute is already gone. Ignore
  # that, then confirm the bundle root is clean. Nested helpers are
  # covered by the recursive delete.
  xattr -dr com.apple.quarantine "$app" 2>/dev/null || true

  if xattr -p com.apple.quarantine "$app" >/dev/null 2>&1; then
    printf 'Could not clear quarantine: %s\n' "$app" >&2
    failed=$((failed + 1))
  elif [[ "$had_quarantine" == true ]]; then
    printf 'Cleared quarantine: %s\n' "$app"
    cleared=$((cleared + 1))
  else
    clean=$((clean + 1))
  fi
done < <(list_cask_apps)

printf 'Quarantine: %d cleared, %d already clean, %d missing, %d failed\n' \
  "$cleared" "$clean" "$missing" "$failed"

if [[ "$failed" -gt 0 ]]; then
  exit 1
fi
