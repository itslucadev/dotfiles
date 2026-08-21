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
# It then trusts the repository configuration and links the three shell
# files that put Homebrew and mise on PATH and that the shell configuration
# reads, so both end up reachable as ordinary commands. Then it stops. The
# actual setup is `mise run setup`, run by hand as the second and last command.

set -Eeuo pipefail

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly EXPECTED_REPO_ROOT="${HOME}/github/phoenix-error/dotfiles"
readonly LOCAL_BIN="${HOME}/.local/bin"
readonly MISE_BIN="${LOCAL_BIN}/mise"
readonly MISE_INSTALLER="${REPO_ROOT}/scripts/setup-mise.sh"

DRY_RUN=false

source "${REPO_ROOT}/scripts/lib.sh"

homebrew_installer=""

cleanup_installers() {
  [[ -n "$homebrew_installer" ]] && rm -f "$homebrew_installer"
  return 0
}

trap cleanup_installers EXIT

usage() {
  printf 'Usage: %s [--dry-run]\n' "${0##*/}"
}

# Homebrew owns /opt/homebrew, which only root can create, so its installer
# escalates with sudo on its own. Under NONINTERACTIVE=1 it validates that
# access with `sudo -n` and aborts with "Need sudo access on macOS" when no
# credentials are cached, which is why the password is requested here, once,
# before the installer starts. The installer itself stays unprivileged, so
# everything it creates keeps belonging to the invoking user.
require_sudo_access() {
  if sudo -n true 2>/dev/null; then
    return 0
  fi

  if [[ ! -t 0 ]]; then
    printf '\nHomebrew needs administrator rights to create /opt/homebrew.\n' >&2
    printf 'An interactive terminal is required.\n' >&2
    printf 'Run `sudo -v`, then run: ./bootstrap.sh\n' >&2
    exit "$MANUAL_ACTION_EXIT"
  fi

  printf '\nHomebrew needs administrator rights to create /opt/homebrew.\n'
  printf 'Enter the password of %s. The installer itself runs unprivileged.\n' "$(id -un)"

  if ! sudo -v; then
    printf 'Administrator rights are required to install Homebrew.\n' >&2
    exit 1
  fi
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

# Everything this script installs belongs to the invoking user. Homebrew's
# installer refuses to run as root outright, and the mise installer, `mise
# trust`, and the dotfile links all write into the home directory, where
# root-owned copies would break every later `mise run setup`. So the script
# declines a privileged run here instead of failing halfway through, and asks
# for a password only at the one stage that genuinely needs one.
if [[ "$EUID" -eq 0 ]]; then
  printf 'Do not run this script as root.\n' >&2
  printf 'Run it without sudo, as %s.\n' "${SUDO_USER:-your ordinary user account}" >&2
  printf 'It asks for a password once, when Homebrew needs administrator rights.\n' >&2
  exit 1
fi

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

# `xcode-select --install` needs no elevation. It only asks macOS to open the
# installer dialog, and the privileged part runs in the system installer, which
# authorizes itself. Only `--switch` and `--reset` require superuser rights, and
# this setup never calls either.
log "Checking Xcode Command Line Tools"
if ! xcode-select -p >/dev/null 2>&1; then
  if [[ "$DRY_RUN" == true ]]; then
    run xcode-select --install
  else
    xcode-select --install || true
    until xcode-select -p >/dev/null 2>&1; do
      manual_step "Finish the Xcode Command Line Tools installation"
      printf '\n  macOS has opened the installer. It brings the compiler\n'
      printf '  toolchain and Git, which every later stage depends on.\n'
      confirm_manual_step "./bootstrap.sh"
    done
  fi
fi

log "Checking Homebrew"
if ! command -v brew >/dev/null 2>&1 && [[ ! -x /opt/homebrew/bin/brew ]]; then
  if [[ "$DRY_RUN" == true ]]; then
    printf '  + request administrator rights for /opt/homebrew with sudo -v\n'
    printf '  + install Homebrew from https://brew.sh\n'
  else
    require_sudo_access
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
#
# The installer is the committed copy of https://mise.run in scripts/. It
# carries the release checksums, so a reviewed copy in the repository is safer
# than downloading and running the script unseen on every fresh Mac. Refresh it
# with `mise run update:mise-installer`. The pinned version it installs matters
# only for a few seconds, because the setup runs `mise self-update` first.
#
# This stage and the two mise stages after it need no elevation. They write to
# ~/.local/bin, to the mise trust store, and to the linked dotfiles, all of
# which belong to the invoking user.
log "Checking mise"
if [[ ! -x "$MISE_BIN" ]]; then
  if [[ "$DRY_RUN" == true ]]; then
    printf '  + install mise with %s into %s\n' "$MISE_INSTALLER" "$MISE_BIN"
  else
    MISE_INSTALL_PATH="$MISE_BIN" MISE_INSTALL_HELP=0 "$MISE_INSTALLER"
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

# Neither Homebrew nor mise is on a fresh Mac's default PATH, and the three
# files that put them there are managed by this repository. Linking just those
# three ends the initialization with both tools reachable as ordinary commands.
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
