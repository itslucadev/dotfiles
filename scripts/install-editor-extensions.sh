#!/usr/bin/env bash

set -Eeuo pipefail

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

DRY_RUN=false
extension_failures=0

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

install_extensions() {
  local editor="$1"
  local extension_file="$2"
  local extension=""

  if [[ "$DRY_RUN" != true ]] && ! command -v "$editor" >/dev/null 2>&1; then
    printf 'Required editor command not found: %s\n' "$editor" >&2
    return 1
  fi

  while IFS= read -r extension || [[ -n "$extension" ]]; do
    if [[ -z "$extension" || "$extension" == \#* ]]; then
      continue
    fi

    if [[ "$DRY_RUN" == true ]]; then
      printf '  + %q --install-extension %q\n' "$editor" "$extension"
    elif ! "$editor" --install-extension "$extension"; then
      printf 'Warning: %s could not install %s\n' "$editor" "$extension" >&2
      extension_failures=$((extension_failures + 1))
    else
      printf 'Installed %s for %s\n' "$extension" "$editor"
    fi
  done <"$extension_file"
}

printf 'Installing VS Code extensions\n'
install_extensions \
  code \
  "$REPO_ROOT/home/.config/editors/extensions.txt"
install_extensions \
  code \
  "$REPO_ROOT/home/.config/editors/vscode/extensions.txt"

printf 'Installing Cursor extensions\n'
install_extensions \
  cursor \
  "$REPO_ROOT/home/.config/editors/extensions.txt"
install_extensions \
  cursor \
  "$REPO_ROOT/home/.config/editors/cursor/extensions.txt"

if [[ "$extension_failures" -gt 0 ]]; then
  printf 'Warning: %d editor extension installation(s) failed.\n' \
    "$extension_failures" >&2
  printf 'Run mise run editors:extensions again, then inspect mise run doctor.\n' >&2
fi
