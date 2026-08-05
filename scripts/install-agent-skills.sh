#!/usr/bin/env bash

set -Eeuo pipefail

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly INVENTORY="$REPO_ROOT/home/.config/skills/default-skills.txt"
readonly SKILLS_CLI_VERSION="1.5.21"
readonly TARGET_AGENTS=("claude-code" "codex" "cursor" "pi")

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

if [[ ! -r "$INVENTORY" ]]; then
  printf 'Agent skill inventory is missing or unreadable: %s\n' "$INVENTORY" >&2
  exit 1
fi

if [[ "$DRY_RUN" != true ]] && ! command -v bunx >/dev/null 2>&1; then
  printf 'bunx is required. Install the mise-managed Bun runtime first.\n' >&2
  exit 1
fi

print_command() {
  local argument=""

  printf '  +'
  for argument in "$@"; do
    printf ' %q' "$argument"
  done
  printf '\n'
}

install_source() {
  local source_url="$1"
  local skill_names="$2"
  local agent=""
  local skill=""
  local -a command=(
    bunx
    --bun
    "skills@${SKILLS_CLI_VERSION}"
    add
    "$source_url"
    --global
    --yes
  )
  local -a skills=()

  read -r -a skills <<<"$skill_names"

  if [[ "${#skills[@]}" -eq 0 ]]; then
    printf 'No skills declared for source: %s\n' "$source_url" >&2
    return 1
  fi

  for skill in "${skills[@]}"; do
    if [[ ! "$skill" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
      printf 'Invalid skill name in inventory: %s\n' "$skill" >&2
      return 1
    fi
    command+=(--skill "$skill")
  done

  for agent in "${TARGET_AGENTS[@]}"; do
    command+=(--agent "$agent")
  done

  # The caller reads the inventory on stdin, so every child gets /dev/null to
  # keep it from consuming inventory lines.
  if [[ "$DRY_RUN" == true ]]; then
    print_command "${command[@]}"
  else
    DISABLE_TELEMETRY=1 "${command[@]}" </dev/null
  fi
}

printf 'Installing the global agent skills for Claude Code, Codex, Cursor, and Pi\n'

source_count=0
skill_count=0
source_url=""
skill_names=""

while IFS='|' read -r source_url skill_names || [[ -n "$source_url$skill_names" ]]; do
  if [[ -z "$source_url" || "$source_url" == \#* ]]; then
    continue
  fi

  if [[ -z "$skill_names" ]]; then
    printf 'Missing skill list for source: %s\n' "$source_url" >&2
    exit 1
  fi

  if [[ ! "$source_url" =~ ^https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+(/tree/[A-Za-z0-9_./-]+)?$ ]]; then
    printf 'Source must be a GitHub repository or tree URL: %s\n' "$source_url" >&2
    exit 1
  fi

  install_source "$source_url" "$skill_names"
  source_count=$((source_count + 1))

  read -r -a source_skills <<<"$skill_names"
  skill_count=$((skill_count + ${#source_skills[@]}))
done <"$INVENTORY"

if [[ "$source_count" -eq 0 ]]; then
  printf 'The agent skill inventory is empty: %s\n' "$INVENTORY" >&2
  exit 1
fi

if [[ "$DRY_RUN" == true ]]; then
  printf 'Would install %d skills from %d sources.\n' "$skill_count" "$source_count"
else
  printf 'Installed %d skills from %d sources.\n' "$skill_count" "$source_count"
fi

# The NotebookLM skill ships inside the NotebookLM CLI package and is installed
# by that CLI, so it cannot come from the inventory above.
printf '\nInstalling the NotebookLM skill through its own CLI\n'

if [[ "$DRY_RUN" != true ]] && ! command -v nlm >/dev/null 2>&1; then
  printf 'nlm was not found. Install the mise-managed NotebookLM CLI first.\n' >&2
  exit 1
fi

for agent in "claude-code" "cursor" "codex"; do
  if [[ "$DRY_RUN" == true ]]; then
    print_command nlm skill install "$agent" --level user
  else
    nlm skill install "$agent" --level user
  fi
done
