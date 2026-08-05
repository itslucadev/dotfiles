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

install_editor_extensions() {
  local editor="$1"
  shift

  local installed_extensions=""
  local extension=""
  local extension_file=""

  if [[ "$DRY_RUN" != true ]] && ! command -v "$editor" >/dev/null 2>&1; then
    printf 'Required editor command not found: %s\n' "$editor" >&2
    return 1
  fi

  # A failing --list-extensions would otherwise yield an empty list, which reads
  # as "nothing is installed yet" and hides the real error.
  if [[ "$DRY_RUN" != true ]]; then
    if ! installed_extensions="$("$editor" --list-extensions)"; then
      printf 'Could not list installed extensions for %s\n' "$editor" >&2
      return 1
    fi
    installed_extensions="$(printf '%s' "$installed_extensions" | tr '[:upper:]' '[:lower:]')"
  fi

  # Calling this function inside an `if !` disables set -e for the whole body,
  # so an unreadable inventory has to be caught explicitly.
  for extension_file in "$@"; do
    if [[ ! -r "$extension_file" ]]; then
      printf 'Extension inventory is missing or unreadable: %s\n' "$extension_file" >&2
      return 1
    fi
  done

  for extension_file in "$@"; do
    while IFS= read -r extension || [[ -n "$extension" ]]; do
      if [[ -z "$extension" || "$extension" == \#* ]]; then
        continue
      fi

      if [[ "$DRY_RUN" == true ]]; then
        printf '  + %q --install-extension %q\n' "$editor" "$extension"
      elif grep -Fxiq "$extension" <<<"$installed_extensions"; then
        printf 'Already installed for %s: %s\n' "$editor" "$extension"
      elif ! "$editor" --install-extension "$extension"; then
        printf 'Warning: %s could not install %s\n' "$editor" "$extension" >&2
        extension_failures=$((extension_failures + 1))
      else
        printf 'Installed %s for %s\n' "$extension" "$editor"
        installed_extensions="${installed_extensions}"$'\n'"${extension}"
      fi
    done <"$extension_file"
  done
}

# Each editor runs independently. A missing editor command must not stop the
# other editor from being configured, and it must not be silently forgiven
# either, so it counts as a failure and the script exits non-zero at the end.
printf 'Installing VS Code extensions\n'
if ! install_editor_extensions \
  code \
  "$REPO_ROOT/home/.config/editors/extensions.txt" \
  "$REPO_ROOT/home/.config/editors/vscode/extensions.txt"; then
  extension_failures=$((extension_failures + 1))
fi

printf 'Installing Cursor extensions\n'
if ! install_editor_extensions \
  cursor \
  "$REPO_ROOT/home/.config/editors/extensions.txt" \
  "$REPO_ROOT/home/.config/editors/cursor/extensions.txt"; then
  extension_failures=$((extension_failures + 1))
fi

if [[ "$extension_failures" -gt 0 ]]; then
  printf 'Warning: %d editor extension installation(s) failed.\n' \
    "$extension_failures" >&2
  printf 'Run mise run editors:extensions again, then inspect mise run doctor.\n' >&2
  exit 1
fi
