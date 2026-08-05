#!/usr/bin/env bash

# The managed part of the setup, owned by the `setup` mise task.
#
# Everything here assumes that `bootstrap.sh` already installed the Xcode
# Command Line Tools, Homebrew, and mise. Run this through `mise run setup`,
# or through `./bootstrap.sh` on a Mac that has not been initialized yet.

set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

DRY_RUN=false

source "${SCRIPT_DIR}/lib.sh"

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

if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

export PATH="${HOME}/.local/bin:${PATH}"

if [[ "$DRY_RUN" != true ]]; then
  for required_command in brew mise; do
    if ! command -v "$required_command" >/dev/null 2>&1; then
      printf '%s is missing. Run ./bootstrap.sh first.\n' "$required_command" >&2
      exit 1
    fi
  done
fi

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

ensure_github_manual_setup() {
  if [[ "$DRY_RUN" == true ]]; then
    print_github_manual_setup_instructions
    printf '  + verify global Git identity\n'
    printf '  + verify ~/.ssh/id_ed25519{,.pub}\n'
    printf '  + verify ssh -T git@github.com authenticates\n'
    return
  fi

  if github_manual_setup_ready; then
    printf 'Git identity and GitHub SSH authentication are ready.\n'
    return
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
}

cd "$REPO_ROOT"

# mise is not in Brewfile, so brew bundle no longer keeps it current.
# This stage takes over that job.
log "Updating mise"
run mise self-update --yes

log "Installing Homebrew formulae and casks"
run brew bundle --file "$REPO_ROOT/Brewfile"

log "Removing unmanaged Homebrew formulae, casks, and taps"
run brew bundle cleanup \
  --force \
  --formula \
  --cask \
  --tap \
  --file "$REPO_ROOT/Brewfile"

# Git comes from Brewfile. Identity, the SSH key, GitHub registration, and
# ssh -T are done by hand here before anything else that needs them.
log "Waiting for manual Git identity and GitHub SSH setup"
ensure_github_manual_setup

# The runtimes install first because other backends depend on them. The pipx
# backend needs uv, and every npm-backed tool needs bun as its package manager.
log "Installing locked language runtimes"
run mise install uv bun node python java ruff

log "Installing locked global CLIs"
run mise install

log "Applying managed dotfiles"
run mise bootstrap dotfiles apply --yes

log "Installing Herdr agent integrations"
run_script "$REPO_ROOT/scripts/install-herdr-integrations.sh"

log "Applying macOS defaults"
run mkdir -p "$HOME/Developer/appzudio"
run mise bootstrap macos defaults apply --yes

log "Installing Mac App Store applications"
run_script "$REPO_ROOT/scripts/install-mas-apps.sh"

log "Setup status"
if [[ "$DRY_RUN" == true ]]; then
  run "$REPO_ROOT/scripts/doctor.sh"
else
  mise exec -- "$REPO_ROOT/scripts/doctor.sh" || true
fi

printf '\nRepository setup finished.\n'
printf 'Open docs/setup-guide.html and complete the manual checklist.\n'
printf 'Install the global agent skills by hand from docs/agent-skills.md.\n'
printf 'Then run: mise run doctor\n'
