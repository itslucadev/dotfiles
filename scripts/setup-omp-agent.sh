#!/usr/bin/env bash

# ~/.omp/agent/config.yml is machine state that omp rewrites at runtime, so
# this repository never symlinks it. This script converges the desired
# settings snapshot through omp's own CLI (`omp config set`), which is
# idempotent because setting the same value twice is a no-op.
#
# The snapshot lives in omp-agent-settings.json next to this script.
# Records and arrays are written as one JSON value per key because the
# CLI does not address nested record fields individually.

set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SETTINGS_FILE="$SCRIPT_DIR/omp-agent-settings.json"

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

if [[ ! -f "$SETTINGS_FILE" ]]; then
  printf 'Missing settings snapshot: %s\n' "$SETTINGS_FILE" >&2
  exit 1
fi

if [[ "$DRY_RUN" != true ]] && ! command -v omp >/dev/null 2>&1; then
  printf 'omp was not found. Apply the Brewfile first.\n' >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  printf 'python3 was not found. It is required to read %s.\n' "$SETTINGS_FILE" >&2
  exit 1
fi

apply_set() {
  local key="$1"
  local value="$2"

  if [[ "$DRY_RUN" == true ]]; then
    printf '  + omp config set %s %s\n' "$key" "$value"
    return 0
  fi

  omp config set "$key" "$value"
}

printf 'Configuring Oh My Pi from %s\n' "$SETTINGS_FILE"

while IFS=$'\t' read -r key value; do
  apply_set "$key" "$value"
done < <(
  python3 - "$SETTINGS_FILE" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, encoding="utf-8") as handle:
    settings = json.load(handle)

if not isinstance(settings, dict):
    raise SystemExit(f"{path} must be a JSON object of omp config keys")

for key, raw in settings.items():
    if not isinstance(key, str) or not key:
        raise SystemExit(f"invalid omp config key: {key!r}")
    if isinstance(raw, bool):
        value = "true" if raw else "false"
    elif isinstance(raw, (dict, list)):
        value = json.dumps(raw, separators=(",", ":"), ensure_ascii=False)
    elif raw is None:
        raise SystemExit(f"{key} must not be null")
    else:
        value = str(raw)
    print(f"{key}\t{value}")
PY
)

if [[ "$DRY_RUN" != true ]]; then
  omp config get modelRoles
  omp config get memory.backend
  omp config get vault.enabled
  omp config get secrets.enabled
  omp config get github.enabled
  omp config get generate_image.enabled
  omp config get providers.imageOrder
  omp config get security.enabled
fi
