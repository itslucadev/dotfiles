#!/usr/bin/env bash

# Bare-metal initialization for a fresh Apple Silicon Mac.
#
# This script installs only the three things that cannot come from managed
# configuration, because nothing that could install them exists yet:
#
#   1. Xcode Command Line Tools, which provide the compiler toolchain and git
#   2. Homebrew, which owns native binaries, casks, and fonts
#   3. mise, which owns runtimes, global CLIs, dotfiles, and the setup tasks
#
# It then trusts the repository configuration and links the two shell dotfiles
# that put Homebrew and mise on PATH, so both end up reachable as ordinary
# commands. Then it stops. The actual setup is `mise run setup`, run by hand as
# the second and last command.

set -Eeuo pipefail

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly EXPECTED_REPO_ROOT="${HOME}/github/phoenix-error/dotfiles"
readonly LOCAL_BIN="${HOME}/.local/bin"
readonly MISE_BIN="${LOCAL_BIN}/mise"

DRY_RUN=false

source "${REPO_ROOT}/scripts/lib.sh"

homebrew_installer=""
mise_installer=""

cleanup_installers() {
  [[ -n "$homebrew_installer" ]] && rm -f "$homebrew_installer"
  [[ -n "$mise_installer" ]] && rm -f "$mise_installer"
  return 0
}

trap cleanup_installers EXIT

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

cd "$REPO_ROOT"

log "Checking Xcode Command Line Tools"
if ! xcode-select -p >/dev/null 2>&1; then
  if [[ "$DRY_RUN" == true ]]; then
    run xcode-select --install
  else
    xcode-select --install || true
    until xcode-select -p >/dev/null 2>&1; do
      wait_for_manual_action \
        "Finish the Xcode Command Line Tools installation." \
        "./bootstrap.sh"
    done
  fi
fi

log "Checking Homebrew"
if ! command -v brew >/dev/null 2>&1 && [[ ! -x /opt/homebrew/bin/brew ]]; then
  if [[ "$DRY_RUN" == true ]]; then
    printf '  + install Homebrew from https://brew.sh\n'
  else
    homebrew_installer="$(mktemp)"
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

# mise comes from its own installer and is deliberately absent from Brewfile.
# It has to exist before the Brewfile is applied, and `brew bundle cleanup`
# must never be able to remove the binary that drives the rest of the setup.
# The check targets the install path rather than PATH so a Mac that still has
# the old Homebrew mise replaces it here instead of losing it during cleanup.
log "Checking mise"
if [[ ! -x "$MISE_BIN" ]]; then
  if [[ "$DRY_RUN" == true ]]; then
    printf '  + install mise from https://mise.run into %s\n' "$MISE_BIN"
  else
    mise_installer="$(mktemp)"
    curl -fsSL https://mise.run -o "$mise_installer"
    MISE_INSTALL_PATH="$MISE_BIN" sh "$mise_installer"
  fi
fi

export PATH="${LOCAL_BIN}:${PATH}"

if [[ "$DRY_RUN" != true ]] && [[ ! -x "$MISE_BIN" ]]; then
  printf 'mise was not found at %s after installation.\n' "$MISE_BIN" >&2
  exit 1
fi

# The setup task lives in mise.toml, so the configuration has to be trusted
# before mise will read it.
log "Trusting the repository mise configuration"
run "$MISE_BIN" trust "$REPO_ROOT/mise.toml"

# Neither Homebrew nor mise is on a fresh Mac's default PATH, and the two files
# that put them there are managed by this repository. Linking just those two
# ends the initialization with both tools reachable as ordinary commands.
#
# This deliberately runs without --force. mise refuses to replace a dotfile it
# does not own, so a Mac with a hand-written ~/.zshrc keeps it and falls back to
# the absolute path below instead of losing the file.
log "Linking the managed shell configuration"
if run "$MISE_BIN" bootstrap dotfiles apply --yes \
  "~/.zprofile" \
  "~/.zshrc" \
  "~/.zsh_plugins.txt"; then
  shell_configuration_linked=true
else
  shell_configuration_linked=false
  printf 'The managed shell configuration was not linked.\n' >&2
  printf 'The setup task applies it later together with every other dotfile.\n' >&2
fi

printf '\nInitialization finished. Homebrew and mise are ready.\n'

if [[ "$shell_configuration_linked" == true ]]; then
  printf 'Open a new terminal so the shell picks both up, then run: mise run setup\n'
else
  printf 'Now run: %s run setup\n' "$MISE_BIN"
fi

printf 'It applies the setup and pauses for the manual steps it needs.\n'
