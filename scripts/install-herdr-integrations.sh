#!/usr/bin/env bash

# Herdr owns its own agent hooks. This repository never copies a generated hook
# file into home/; it only asks Herdr to install and verify its integrations.
# See https://herdr.dev/docs/integrations/

set -Eeuo pipefail

readonly INTEGRATIONS=("claude" "codex" "cursor" "omp" "pi")

DRY_RUN=false

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

if [[ "$DRY_RUN" != true ]] && ! command -v herdr >/dev/null 2>&1; then
  printf 'herdr was not found. Apply the Brewfile first.\n' >&2
  exit 1
fi

printf 'Installing Herdr agent integrations\n'

for integration in "${INTEGRATIONS[@]}"; do
  if [[ "$DRY_RUN" == true ]]; then
    printf '  + herdr integration install %s\n' "$integration"
    continue
  fi

  herdr integration install "$integration"
done

if [[ "$DRY_RUN" != true ]]; then
  herdr integration status
fi
