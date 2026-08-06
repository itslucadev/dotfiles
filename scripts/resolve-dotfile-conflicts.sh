#!/usr/bin/env bash

# The dotfile conflict gate of the managed setup, run as the last `pre-dotfiles`
# bootstrap hook in mise.toml, right before mise links the entries from
# `[dotfiles]`.
#
# mise refuses to overwrite a target that already exists as a real file, and it
# stops the whole bootstrap when it finds one. That is the correct default, but
# it is also the normal state of a Mac whose coding agents were signed in before
# the setup ran: Claude Code writes `~/.claude/settings.json` on its first
# start, and from then on every `mise run setup` fails at the dotfiles stage.
#
# This script asks instead of deciding. It lists the conflicting targets, waits
# for an explicit yes, and then moves each one aside with a timestamp. Nothing
# is deleted, and mise links the managed version afterwards. A no leaves the Mac
# untouched and fails the hook, which halts the bootstrap.

set -Eeuo pipefail

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "${REPO_ROOT}/scripts/lib.sh"

readonly BACKUP_SUFFIX="pre-dotfiles-backup.$(date +%Y%m%d-%H%M%S)"

# Paths are reported the way mise and the configuration write them, so a listed
# target stays recognizable in mise.toml.
home_relative() {
  local path="$1"

  if [[ "$path" == "${HOME}/"* ]]; then
    printf '~%s' "${path#"${HOME}"}"
    return
  fi

  printf '%s' "$path"
}

# The targets mise would refuse to overwrite, newline separated.
#
# `state` alone is not enough. A target also counts as differing when it is a
# symlink into the wrong place, and mise replaces those by itself. Only a target
# that exists and is not a symlink is a real file with content that could be
# lost, which is exactly the case mise declines to touch.
conflicting_targets() {
  local target=""

  while IFS= read -r target; do
    [[ -n "$target" ]] || continue

    target="${target/#\~\//${HOME}/}"

    if [[ -e "$target" && ! -L "$target" ]]; then
      printf '%s\n' "$target"
    fi
  done < <(
    mise bootstrap dotfiles status --json |
      jq -r '.files[] | select(.state == "differs") | .target'
  )
}

print_conflict_instructions() {
  local conflicts="$1"
  local target=""

  manual_step "Existing files are in the way of the managed dotfiles"

  printf '\n  These paths already hold real files, so mise stops rather than\n'
  printf '  overwrite them. This is expected when an application wrote its own\n'
  printf '  configuration before the setup ran, and Claude Code does exactly\n'
  printf '  that on its first start.\n'
  printf '\n  Affected:\n\n'

  while IFS= read -r target; do
    [[ -n "$target" ]] || continue

    printf '    %s\n' "$(home_relative "$target")"
  done <<<"$conflicts"

  printf '\n  Answering yes moves each of them to `<file>.%s`\n' "$BACKUP_SUFFIX"
  printf '  and lets mise link the managed version. Nothing is deleted, and the\n'
  printf '  backup can be compared or restored afterwards.\n'
  printf '\n  Answering no stops the setup and changes nothing.\n'
}

# lib.sh confirms a completed manual step with a bare Return, which is the wrong
# default for a step that moves files. This one needs the word.
confirm_overwrite() {
  local answer=""

  if [[ ! -t 0 ]]; then
    printf '\n  An interactive terminal is required to answer this.\n' >&2
    printf '  Move the listed files aside yourself, then run: mise run setup\n\n' >&2
    exit "$MANUAL_ACTION_EXIT"
  fi

  printf '\n  Move them aside and continue? Answer y to overwrite, anything\n'
  printf '  else to stop.\n'
  rule

  if ! read -r answer; then
    printf '\n  Input ended before the question was answered.\n' >&2
    exit "$MANUAL_ACTION_EXIT"
  fi

  [[ "$answer" =~ ^([yY]|[yY][eE][sS])$ ]]
}

back_up_conflicts() {
  local conflicts="$1"
  local target=""
  local backup=""

  while IFS= read -r target; do
    [[ -n "$target" ]] || continue

    backup="${target}.${BACKUP_SUFFIX}"

    mv "$target" "$backup"
    printf '  moved %s\n' "$(home_relative "$target")"
    printf '     to %s\n' "$(home_relative "$backup")"
  done <<<"$conflicts"
}

log "Checking for files in the way of the managed dotfiles"

conflicts="$(conflicting_targets)"

if [[ -z "$conflicts" ]]; then
  printf 'No dotfile conflicts.\n'
  exit 0
fi

print_conflict_instructions "$conflicts"

if ! confirm_overwrite; then
  printf '\n  Left untouched. The dotfiles stage cannot run while they exist.\n' >&2
  printf '  Move or delete them yourself, then run: mise run setup\n\n' >&2
  exit 1
fi

printf '\n'
back_up_conflicts "$conflicts"
