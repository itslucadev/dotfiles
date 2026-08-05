#!/usr/bin/env bash

# The manual Git and GitHub gate of the managed setup, run as the
# `pre-dotfiles` bootstrap hook in mise.toml, right after Homebrew installed
# Git and before anything that needs an authenticated GitHub.
#
# Identity, the SSH key, the GitHub registration, and `ssh -T` are done by hand.
# This script blocks until `ssh -T git@github.com` authenticates, and checks
# nothing else. That one connection is what the later stages depend on, and it
# only succeeds once the whole checklist below has been worked through.

set -Eeuo pipefail

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly SETUP_GUIDE="${REPO_ROOT}/docs/setup-guide.html"

source "${REPO_ROOT}/scripts/lib.sh"

# A numbered item of the checklist, and the commands or notes belonging to it.
item() {
  printf '\n  %s%s  %s%s\n' "$BOLD" "$1" "$2" "$RESET"
}

detail() {
  printf '       %s\n' "$1"
}

# GitHub answers a working `ssh -T` with a greeting and then exits non-zero, so
# the greeting is what decides here, not the exit status.
#
# BatchMode keeps ssh from asking anything. Its prompts go to stderr, which
# this command substitution captures, so the question about an unknown host key
# would sit invisibly on the screen and eat every Return pressed at the gate
# below, leaving the setup looking like it had stopped.
github_ssh_auth_works() {
  local ssh_output=""

  ssh_output="$(
    ssh -T \
      -o BatchMode=yes \
      -o ConnectTimeout=10 \
      git@github.com </dev/null 2>&1 || true
  )"

  grep -Fq 'successfully authenticated' <<<"$ssh_output"
}

print_github_manual_setup_instructions() {
  manual_step "Set up Git and GitHub SSH"

  printf '\n  Homebrew has installed Git. The setup continues as soon as this\n'
  printf '  reports successful authentication:\n'
  printf '\n    ssh -T git@github.com\n'
  printf '\n  The walkthrough is the %sGit, SSH und GitHub%s phase of the setup guide:\n' \
    "$BOLD" "$RESET"
  printf '    %s\n' "$SETUP_GUIDE"
  printf '\n  In short:\n'

  item 1 "Set your Git identity"
  detail 'git config --global user.name "Your Name"'
  detail 'git config --global user.email "you@example.com"'

  item 2 "Create an SSH configuration and an Ed25519 key"
  detail '~/.ssh/config and a key pair at ~/.ssh/id_ed25519'

  item 3 "Register the public key on GitHub"
  detail 'Add it twice, as an Authentication key and as a Signing key'

  item 4 "Run the connection once yourself"
  detail 'Compare the host fingerprint with GitHub documentation, then answer'
  detail 'yes. This setup deliberately never answers that question for you.'
}

log "Checking the GitHub SSH authentication"

if github_ssh_auth_works; then
  printf 'GitHub SSH authentication is ready.\n'
  exit 0
fi

print_github_manual_setup_instructions

while true; do
  confirm_manual_step "mise run setup"

  if github_ssh_auth_works; then
    break
  fi

  printf '\n  %sNot yet:%s ssh -T git@github.com did not authenticate.\n' \
    "$BOLD" "$RESET" >&2
done

printf 'GitHub SSH authentication is ready.\n'
