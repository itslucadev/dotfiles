#!/usr/bin/env bash

# The Mac App Store stage of the managed setup, run as a `final` bootstrap hook
# in mise.toml.

set -Eeuo pipefail

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "${REPO_ROOT}/scripts/lib.sh"

DRY_RUN=false
TEMPORARY_OUTPUT=""
SUDO_KEEPALIVE_PID=""

cleanup() {
  if [[ -n "$SUDO_KEEPALIVE_PID" ]]; then
    kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
  fi

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

# `brew bundle` installs as many entries at once as `HOMEBREW_BUNDLE_JOBS`
# allows, and that default is the number of cores capped at four. Its parallel
# installer holds a lock around a cask for the whole installation, precisely
# because a cask can ask for a password, but a Mac App Store entry gets no such
# treatment. Four applications then announce themselves at once, in thread order
# rather than Brewfile order, and the password prompt that `mas` triggers lands
# under whichever line happened to print last, belonging to none of them.
#
# One entry at a time restores the reading a person expects: the line above the
# prompt names the application that is being installed. It costs the overlap
# between two downloads, which is a fair price on a run that installs a fresh
# Mac exactly once, and matches the serial download the Homebrew stage already
# chose for the same reason.
export HOMEBREW_BUNDLE_NO_JOBS=1

# Homebrew runs `mas` through a helper that captures the child output and prints
# it only when the installation fails. That is a reasonable default for a quiet
# log, and the wrong one here: Xcode downloads for a long time, and a stage that
# prints nothing at all is indistinguishable from a stage that has hung.
# `--verbose` passes the `mas` output straight through instead.
run_bundle() {
  if brew bundle --file "$REPO_ROOT/Brewfile.mas" --verbose 2>&1 |
    tee "$TEMPORARY_OUTPUT"; then
    return 0
  else
    return "${PIPESTATUS[0]}"
  fi
}

is_manual_app_store_error() {
  grep -Eiq \
    'not signed.*App Store|sign in.*App Store|Apple (Account|ID)|redownload is not available|authori[sz]ation is required|not (been )?(purchased|acquired|gotten)' \
    "$TEMPORARY_OUTPUT"
}

# `mas install` requires root and re-executes itself under sudo, so a password
# is requested whether or not this script asks for one. Asking here, before the
# first download starts, is the difference between a prompt that explains itself
# and a bare `Password:` in the middle of Homebrew's output.
require_sudo_access() {
  if sudo -n -v 2>/dev/null; then
    return 0
  fi

  if [[ ! -t 0 ]]; then
    printf '\nThe Mac App Store applications install with administrator rights.\n' >&2
    printf 'An interactive terminal is required.\n' >&2
    printf 'Run `sudo -v`, then run: mise run apps:mas\n' >&2
    exit "$MANUAL_ACTION_EXIT"
  fi

  printf '\n  `mas` installs applications with administrator rights.\n'
  printf '  Enter the password of %s. It is requested once, here.\n\n' "$(id -un)"

  if ! sudo -v; then
    printf 'Administrator rights are required to install the Mac App Store applications.\n' >&2
    exit 1
  fi
}

# The sudo timestamp expires after five minutes, and Xcode alone downloads for
# far longer than that, so every application behind it would meet a fresh
# prompt, printed by `mas` from inside Homebrew with nothing around it. Holding
# the timestamp open for the length of the stage keeps the password to the
# single, explained request above.
#
# The refresher stops with this script through the EXIT trap, and gives up on
# its own if the script dies without running it or the timestamp disappears.
start_sudo_keepalive() {
  local parent="$$"

  while kill -0 "$parent" 2>/dev/null && sudo -n -v 2>/dev/null; do
    sleep 60
  done &

  SUDO_KEEPALIVE_PID=$!
}

if [[ "$DRY_RUN" == true ]]; then
  printf '  + brew bundle --file %q --verbose\n' "$REPO_ROOT/Brewfile.mas"
  exit 0
fi

log "Installing the Mac App Store applications"

# Every rerun of the setup passes through here, and asking a person for a
# password to then install nothing is the kind of prompt that teaches them to
# type it without reading. This stage stays silent unless it has work to do.
if brew bundle check --file "$REPO_ROOT/Brewfile.mas" >/dev/null 2>&1; then
  printf '\nMac App Store applications are installed.\n'
  exit 0
fi

printf '\n  The applications install one at a time, in Brewfile order, and the\n'
printf '  line above each installation names the one it is downloading.\n'
printf '  Xcode is several gigabytes, so its line can stand alone for a long\n'
printf '  while before the next one appears.\n'

require_sudo_access
start_sudo_keepalive

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
