#!/usr/bin/env bash

# Compare the live omp config against scripts/omp-agent-settings.json.
# Tracked keys that drifted on this Mac are written back into the snapshot
# so a later bootstrap on another machine can replay them.
#
# The launchd agent from scripts/setup-omp-sync.sh runs this every evening.
# It never commits and never pushes. Review the JSON diff and commit it.

set -Eeuo pipefail

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly SETTINGS_FILE="$REPO_ROOT/scripts/omp-agent-settings.json"

source "${REPO_ROOT}/scripts/lib.sh"

# launchd starts this with a minimal environment, so rebuild the PATH that
# an interactive shell gets from ~/.zprofile and ~/.zshrc.
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
export PATH="$HOME/.local/bin:$PATH"

DRY_RUN=false
CHECK_ONLY=false

usage() {
  printf 'Usage: %s [--dry-run] [--check]\n' "${0##*/}"
}

for argument in "$@"; do
  case "$argument" in
    --dry-run)
      DRY_RUN=true
      ;;
    --check)
      CHECK_ONLY=true
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

if ! command -v python3 >/dev/null 2>&1; then
  printf 'python3 was not found.\n' >&2
  exit 1
fi

if ! command -v omp >/dev/null 2>&1; then
  printf 'omp was not found. Skipping the evening settings check.\n'
  exit 0
fi

printf '\n===== omp settings check: %s =====\n' "$(date '+%Y-%m-%d %H:%M:%S')"

export SETTINGS_FILE DRY_RUN CHECK_ONLY
python3 - <<'PY'
import json
import os
import subprocess
import sys

settings_path = os.environ["SETTINGS_FILE"]
dry_run = os.environ["DRY_RUN"] == "true"
check_only = os.environ["CHECK_ONLY"] == "true"

with open(settings_path, encoding="utf-8") as handle:
    snapshot = json.load(handle)

if not isinstance(snapshot, dict):
    raise SystemExit(f"{settings_path} must be a JSON object")


def dump(value):
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


changed = []
for key, desired in snapshot.items():
    result = subprocess.run(
        ["omp", "config", "get", key, "--json"],
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        print(f"FAIL  {key}: {result.stderr.strip() or result.stdout.strip()}", file=sys.stderr)
        raise SystemExit(1)
    payload = json.loads(result.stdout)
    live = payload.get("value")
    if dump(live) == dump(desired):
        continue
    changed.append((key, desired, live))
    snapshot[key] = live

if not changed:
    print("omp settings match the snapshot")
    raise SystemExit(0)

print(f"{len(changed)} tracked key(s) drifted:")
for key, desired, live in changed:
    print(f"  {key}")
    print(f"    snapshot: {dump(desired)}")
    print(f"    live:     {dump(live)}")

if check_only:
    raise SystemExit(2)

if dry_run:
    print("dry-run: snapshot not written")
    raise SystemExit(0)

with open(settings_path, "w", encoding="utf-8") as handle:
    json.dump(snapshot, handle, indent=2, ensure_ascii=False)
    handle.write("\n")

print(f"Wrote {settings_path}")
print("Commit the snapshot when you want this Mac's settings on the next machine.")
raise SystemExit(0)
PY
status=$?

if [[ "$status" -eq 0 && "$DRY_RUN" != true && "$CHECK_ONLY" != true ]]; then
  if command -v osascript >/dev/null 2>&1; then
    osascript -e 'display notification "omp-agent-settings.json updated from this Mac. Commit when ready." with title "Dotfiles"' >/dev/null 2>&1 || true
  fi
fi

exit "$status"
