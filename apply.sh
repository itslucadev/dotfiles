#!/usr/bin/env bash

set -Eeuo pipefail

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly EXPECTED_REPO_ROOT="${HOME}/github/phoenix-error/dotfiles"

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

if [[ "$REPO_ROOT" != "$EXPECTED_REPO_ROOT" && "$DRY_RUN" != true ]]; then
  printf 'Clone this repository at %s before applying the setup.\n' "$EXPECTED_REPO_ROOT" >&2
  exit 1
fi

if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

if [[ "$DRY_RUN" != true ]] && ! command -v brew >/dev/null 2>&1; then
  printf 'Required command not found: brew\n' >&2
  exit 1
fi

cd "$REPO_ROOT"

log "Installing Homebrew formulae and casks"
run brew bundle --file "$REPO_ROOT/Brewfile"

if [[ "$DRY_RUN" != true ]] && ! command -v mise >/dev/null 2>&1; then
  printf 'mise was not found after applying Brewfile.\n' >&2
  exit 1
fi

log "Trusting the repository mise configuration"
run mise trust "$REPO_ROOT/mise.toml"

log "Installing locked runtimes and global CLIs"
run mise install

log "Applying managed dotfiles"
run mise bootstrap dotfiles apply --yes

log "Installing managed editor extensions"
if [[ "$DRY_RUN" == true ]]; then
  run "$REPO_ROOT/scripts/install-editor-extensions.sh" --dry-run
else
  "$REPO_ROOT/scripts/install-editor-extensions.sh"
fi

log "Applying macOS defaults"
run mkdir -p "$HOME/Pictures/Screenshots"
run mkdir -p "$HOME/Developer/appzudio"
run mise bootstrap macos defaults apply --yes

log "Applying dynamic and nested macOS settings"
if [[ "$DRY_RUN" == true ]]; then
  run "$REPO_ROOT/scripts/configure-macos.sh" --dry-run
else
  "$REPO_ROOT/scripts/configure-macos.sh"
fi

log "Installing Raycast v2 Beta"
if [[ "$DRY_RUN" == true ]]; then
  run "$REPO_ROOT/scripts/install-raycast-beta.sh" --dry-run
else
  "$REPO_ROOT/scripts/install-raycast-beta.sh"
fi

log "Installing Mac App Store applications"
if [[ "$DRY_RUN" == true ]]; then
  run brew bundle --file "$REPO_ROOT/Brewfile.mas"
else
  if brew bundle --file "$REPO_ROOT/Brewfile.mas"; then
    printf 'Mac App Store applications are installed.\n'
  else
    printf 'Warning: Xcode or RocketSim could not be installed automatically.\n' >&2
    printf 'Sign in to the App Store, claim both applications if necessary, and run: mise run apps:mas\n'
  fi
fi

log "Setup status"
if [[ "$DRY_RUN" == true ]]; then
  run "$REPO_ROOT/scripts/doctor.sh"
else
  mise exec -- "$REPO_ROOT/scripts/doctor.sh" || true
fi

printf '\nRepository setup finished.\n'
printf 'Complete the manual checklist in README.md, then run: mise run doctor\n'
