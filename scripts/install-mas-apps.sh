#!/usr/bin/env bash

set -Eeuo pipefail

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "${REPO_ROOT}/scripts/lib.sh"

DRY_RUN=false
TEMPORARY_OUTPUT=""

cleanup() {
  if [[ -n "$TEMPORARY_OUTPUT" ]]; then
    rm -f "$TEMPORARY_OUTPUT"
  fi
}

trap cleanup EXIT

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

is_manual_app_store_error() {
  grep -Eiq \
    'not signed.*App Store|sign in.*App Store|Apple (Account|ID)|redownload is not available|authori[sz]ation is required|not (been )?(purchased|acquired|gotten)' \
    "$TEMPORARY_OUTPUT"
}

run_bundle() {
  if brew bundle --file "$REPO_ROOT/Brewfile.mas" 2>&1 |
    tee "$TEMPORARY_OUTPUT"; then
    return 0
  else
    return "${PIPESTATUS[0]}"
  fi
}

if [[ "$DRY_RUN" == true ]]; then
  printf '  + brew bundle --file %q\n' "$REPO_ROOT/Brewfile.mas"
  exit 0
fi

TEMPORARY_OUTPUT="$(mktemp)"

while true; do
  if run_bundle; then
    break
  else
    bundle_status=$?
  fi

  if ! is_manual_app_store_error; then
    printf 'Mac App Store installation failed without a recognized login or claim error.\n' >&2
    exit "$bundle_status"
  fi

  manual_step "Sign in to the Mac App Store and claim the applications"

  printf '\n  The App Store reported the error above. An application that this\n'
  printf '  Apple Account has never downloaded has to be claimed once, by hand,\n'
  printf '  before it can be installed without a person at the keyboard.\n'
  printf '\n  Sign in, then claim every managed application the error names.\n'

  if [[ -t 0 ]]; then
    open -a "App Store" || true
  fi

  confirm_manual_step "mise run apps:mas"
done

printf 'Mac App Store applications are installed.\n'
