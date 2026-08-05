#!/usr/bin/env bash

# Shared helpers for the setup scripts. Source this file, do not execute it.
#
# `run` exists for bootstrap.sh, which owns its own --dry-run. The managed
# stages need no equivalent, because `mise bootstrap --dry-run` prints their
# hooks instead of running them. Every consumer of `run` declares its own
# DRY_RUN variable before sourcing, and the helper reads it lazily so a script
# can flip it while parsing its arguments.

readonly MANUAL_ACTION_EXIT=2

# The setup prints two kinds of output. Progress lines mirror Homebrew's `==> `
# style and are meant to scroll past. A manual step is the opposite: it has to
# be found and read at the bottom of a few hundred lines of installer output,
# so it is framed by rules, titled in bold, and indented as a block.
#
# Emphasis is dropped when stdout is not a terminal or NO_COLOR is set, so a
# piped or redirected log stays plain text.
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  readonly BOLD=$'\033[1m'
  readonly RESET=$'\033[0m'
else
  readonly BOLD=""
  readonly RESET=""
fi

# A rule as wide as the window reads as a divider, and one that overshoots
# wraps into a ragged second line. This caps the width for the wide terminal a
# docked Mac usually has, and falls back to a safe default when the window size
# is unknown, which is the case whenever TERM is unset.
block_width() {
  local columns=""

  if command -v tput >/dev/null 2>&1; then
    columns="$(tput cols 2>/dev/null)" || columns=""
  fi

  if [[ ! "$columns" =~ ^[0-9]+$ ]] || [[ "$columns" -gt 76 ]]; then
    columns=76
  elif [[ "$columns" -lt 32 ]]; then
    columns=32
  fi

  printf '%s' "$columns"
}

readonly BLOCK_WIDTH="$(block_width)"

log() {
  printf '\n==> %s\n' "$1"
}

rule() {
  local blanks=""

  printf -v blanks '%*s' "$BLOCK_WIDTH" ''
  printf '%s\n' "${blanks// /─}"
}

# Run a command, or print it when the caller is in dry-run mode.
run() {
  if [[ "${DRY_RUN:-false}" == true ]]; then
    printf '  +'
    printf ' %q' "$@"
    printf '\n'
    return 0
  fi

  "$@"
}

# Open a block for a step that cannot be automated. A caller with more to say
# than its title prints the body itself, indented by two spaces to match.
manual_step() {
  printf '\n'
  rule
  printf '  %sManual step: %s%s\n' "$BOLD" "$1" "$RESET"
  rule
}

# Close the block, and block until the operator confirms. Every caller verifies
# the result afterwards, so a premature Return costs another round through the
# gate rather than a broken setup.
confirm_manual_step() {
  local rerun_command="$1"

  if [[ ! -t 0 ]]; then
    printf '\n  An interactive terminal is required to continue here.\n' >&2
    printf '  Complete the step, then run: %s\n\n' "$rerun_command" >&2
    exit "$MANUAL_ACTION_EXIT"
  fi

  printf '\n  Press Return once it is done. The setup verifies it before it continues.\n'
  rule

  # Losing stdin, by a closed pipe or by Ctrl-D, would otherwise abort the
  # script through `set -e` with nothing but a shell error to go on.
  if ! read -r; then
    printf '\n  Input ended before the step was confirmed.\n' >&2
    printf '  Complete the step, then run: %s\n\n' "$rerun_command" >&2
    exit "$MANUAL_ACTION_EXIT"
  fi

  # Verifying a step can take a moment, and a gate that answers a keypress with
  # nothing at all is indistinguishable from one that has hung. This is the
  # receipt for the Return that was just pressed.
  printf '\n  Verifying...\n'
}
