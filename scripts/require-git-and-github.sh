#!/usr/bin/env bash

# The manual Git and GitHub gate of the managed setup, run as the
# `pre-dotfiles` bootstrap hook in mise.toml, right after Homebrew installed
# Git and before anything that needs an authenticated GitHub.
#
# Identity, the SSH key, the GitHub registration, and `ssh -T` are done by hand.
# This script only blocks until they are in place, and verifies them.

set -Eeuo pipefail

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "${REPO_ROOT}/scripts/lib.sh"

github_ssh_auth_works() {
  local ssh_output=""

  ssh_output="$(ssh -T git@github.com 2>&1 || true)"
  grep -Fq 'successfully authenticated' <<<"$ssh_output"
}

github_manual_setup_ready() {
  [[ -f "$HOME/.ssh/id_ed25519" && -f "$HOME/.ssh/id_ed25519.pub" ]] &&
    ssh-keygen -lf "$HOME/.ssh/id_ed25519.pub" >/dev/null 2>&1 &&
    [[ "$(awk 'NR == 1 { print $1 }' "$HOME/.ssh/id_ed25519.pub")" == "ssh-ed25519" ]] &&
    git config --global --get user.name >/dev/null 2>&1 &&
    git config --global --get user.email >/dev/null 2>&1 &&
    github_ssh_auth_works
}

print_github_manual_setup_instructions() {
  printf '\nConfigure Git and GitHub SSH by hand now.\n'
  printf 'Homebrew has installed Git. Do the full checklist in README.md:\n'
  printf '  Setting Git and SSH Up by Hand\n'
  printf '\nMinimum required before this setup continues:\n'
  printf '  1. git config --global user.name / user.email\n'
  printf '  2. ~/.ssh/config and an Ed25519 key at ~/.ssh/id_ed25519\n'
  printf '  3. Add the public key on GitHub as Authentication and Signing keys\n'
  printf '  4. Verify with: ssh -T git@github.com\n'
  printf '     Compare the host fingerprint with GitHub documentation first.\n'
}

log "Waiting for manual Git identity and GitHub SSH setup"

if github_manual_setup_ready; then
  printf 'Git identity and GitHub SSH authentication are ready.\n'
  exit 0
fi

print_github_manual_setup_instructions

until github_manual_setup_ready; do
  wait_for_manual_action \
    "Finish the manual Git and GitHub SSH setup, then confirm." \
    "mise run setup"

  if ! git config --global --get user.name >/dev/null 2>&1 ||
    ! git config --global --get user.email >/dev/null 2>&1; then
    printf 'Global Git user.name or user.email is still missing.\n' >&2
    continue
  fi

  if [[ ! -f "$HOME/.ssh/id_ed25519" || ! -f "$HOME/.ssh/id_ed25519.pub" ]]; then
    printf 'Expected ~/.ssh/id_ed25519 and ~/.ssh/id_ed25519.pub.\n' >&2
    continue
  fi

  if ! github_ssh_auth_works; then
    printf 'ssh -T git@github.com did not report successful authentication.\n' >&2
    continue
  fi
done

printf 'Git identity and GitHub SSH authentication are ready.\n'
