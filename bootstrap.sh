#!/usr/bin/env bash

set -Eeuo pipefail

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly EXPECTED_REPO_ROOT="${HOME}/github/phoenix-error/dotfiles"

DRY_RUN=false

log() {
  printf '\n==> %s\n' "$1"
}

run() {
  if [[ "$DRY_RUN" == true ]]; then
    printf '  +'
    printf ' %q' "$@"
    printf '\n'
    return 0
  fi

  "$@"
}

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

if [[ "$(uname -s)" != "Darwin" ]]; then
  printf 'This setup supports macOS only.\n' >&2
  exit 1
fi

if [[ "$(uname -m)" != "arm64" ]]; then
  printf 'This setup supports Apple Silicon Macs only.\n' >&2
  exit 1
fi

if [[ "$REPO_ROOT" != "$EXPECTED_REPO_ROOT" && "$DRY_RUN" != true ]]; then
  printf 'Clone this repository at %s before running the setup.\n' "$EXPECTED_REPO_ROOT" >&2
  exit 1
fi

log "Checking Xcode Command Line Tools"
if ! xcode-select -p >/dev/null 2>&1; then
  if [[ "$DRY_RUN" == true ]]; then
    run xcode-select --install
  else
    xcode-select --install
    printf 'Finish the Command Line Tools installation and run bootstrap.sh again.\n'
    exit 2
  fi
fi

log "Checking Homebrew"
if ! command -v brew >/dev/null 2>&1 && [[ ! -x /opt/homebrew/bin/brew ]]; then
  if [[ "$DRY_RUN" == true ]]; then
    printf '  + install Homebrew from https://brew.sh\n'
  else
    readonly homebrew_installer="$(mktemp)"
    trap 'rm -f "$homebrew_installer"' EXIT
    curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o "$homebrew_installer"
    NONINTERACTIVE=1 /bin/bash "$homebrew_installer"
  fi
fi

if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

if [[ "$DRY_RUN" != true ]] && ! command -v brew >/dev/null 2>&1; then
  printf 'Homebrew was not found after installation.\n' >&2
  exit 1
fi

log "Applying repository setup"
if [[ "$DRY_RUN" == true ]]; then
  run "$REPO_ROOT/apply.sh" --dry-run
else
  exec "$REPO_ROOT/apply.sh"
fi
