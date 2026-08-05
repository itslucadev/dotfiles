#!/usr/bin/env bash

# Shared helpers for the setup scripts. Source this file, do not execute it.
#
# `run` exists for bootstrap.sh, which owns its own --dry-run. The managed
# stages need no equivalent, because `mise bootstrap --dry-run` prints their
# hooks instead of running them. Every consumer of `run` declares its own
# DRY_RUN variable before sourcing, and the helper reads it lazily so a script
# can flip it while parsing its arguments.

readonly MANUAL_ACTION_EXIT=2

log() {
  printf '\n==> %s\n' "$1"
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

# Block until the operator confirms a step that cannot be automated.
wait_for_manual_action() {
  local instruction="$1"
  local rerun_command="$2"

  printf '\nManual action required: %s\n' "$instruction"

  if [[ ! -t 0 ]]; then
    printf 'An interactive terminal is required.\n' >&2
    printf 'Complete the action, then run: %s\n' "$rerun_command" >&2
    exit "$MANUAL_ACTION_EXIT"
  fi

  printf 'Press Return after completing the action. The setup will verify it before continuing.\n'
  read -r
}
