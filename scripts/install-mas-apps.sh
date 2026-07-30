#!/usr/bin/env bash

set -Eeuo pipefail

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly MANUAL_ACTION_EXIT=2

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

  printf '\nManual action required.\n' >&2
  printf 'Resolve the App Store error above.\n' >&2
  printf 'Sign in and claim any managed application that this Apple Account has never downloaded.\n' >&2

  if [[ ! -t 0 ]]; then
    printf 'Then run: mise run apps:mas\n' >&2
    printf 'To continue the complete setup afterward, run: ./bootstrap.sh\n' >&2
    exit "$MANUAL_ACTION_EXIT"
  fi

  open -a "App Store" || true
  printf 'Press Return after completing the action. The setup will verify it before continuing.\n'
  if ! read -r; then
    exit "$MANUAL_ACTION_EXIT"
  fi
done

printf 'Mac App Store applications are installed.\n'
