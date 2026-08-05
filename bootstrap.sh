#!/usr/bin/env bash

set -Eeuo pipefail

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly EXPECTED_REPO_ROOT="${HOME}/github/phoenix-error/dotfiles"
readonly MANUAL_ACTION_EXIT=2

DRY_RUN=false

log() {
  printf '\n==> %s\n' "$1"
}

run() {
  if [[ "$DRY_RUN" == true ]]; then
    printf '  +'
    printf ' %q' "$@"
    printf '\n'
    return 0
  fi

  "$@"
}

# Scripts that implement their own --dry-run handling.
run_script() {
  local script="$1"

  if [[ "$DRY_RUN" == true ]]; then
    "$script" --dry-run
  else
    "$script"
  fi
}

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
    readonly homebrew_installer="$(mktemp)"
    trap 'rm -f "$homebrew_installer"' EXIT
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

cd "$REPO_ROOT"

log "Installing Homebrew formulae and casks"
run brew bundle --file "$REPO_ROOT/Brewfile"

log "Removing unmanaged Homebrew formulae, casks, and taps"
run brew bundle cleanup \
  --force \
  --formula \
  --cask \
  --tap \
  --file "$REPO_ROOT/Brewfile"

if [[ "$DRY_RUN" != true ]] && ! command -v mise >/dev/null 2>&1; then
  printf 'mise was not found after applying Brewfile.\n' >&2
  exit 1
fi

log "Trusting the repository mise configuration"
run mise trust "$REPO_ROOT/mise.toml"

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

log "Installing managed editor extensions"
run_script "$REPO_ROOT/scripts/install-editor-extensions.sh"

log "Applying macOS defaults"
run mkdir -p "$HOME/Developer/appzudio"
run mise bootstrap macos defaults apply --yes

log "Applying dynamic and nested macOS settings"
run_script "$REPO_ROOT/scripts/configure-macos.sh"

# Every remaining stage needs the person at the keyboard, so they run together
# once the unattended work is finished.
log "Configuring GitHub SSH authentication and commit signing"
run_script "$REPO_ROOT/scripts/setup-github-ssh.sh"

log "Installing Raycast v2 Beta"
run_script "$REPO_ROOT/scripts/install-raycast-beta.sh"

log "Installing Mac App Store applications"
run_script "$REPO_ROOT/scripts/install-mas-apps.sh"

# The agent skills run last: their installer verifies each target agent by
# looking for its configuration directory, which only exists once the managed
# dotfiles are in place.
log "Installing the pinned global agent skills"
if [[ "$DRY_RUN" == true ]]; then
  "$REPO_ROOT/scripts/install-agent-skills.sh" --dry-run
else
  mise exec -- "$REPO_ROOT/scripts/install-agent-skills.sh"
fi

log "Setup status"
if [[ "$DRY_RUN" == true ]]; then
  run "$REPO_ROOT/scripts/doctor.sh"
else
  mise exec -- "$REPO_ROOT/scripts/doctor.sh" || true
fi

printf '\nRepository setup finished.\n'
printf 'Open docs/setup-guide.html and complete the manual checklist.\n'
printf 'Then run: mise run doctor\n'
