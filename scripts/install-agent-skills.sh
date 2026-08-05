#!/usr/bin/env bash

set -Eeuo pipefail

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly INVENTORY="$REPO_ROOT/home/.config/skills/default-skills.txt"
readonly SKILLS_CLI_VERSION="1.5.21"
readonly TARGET_AGENTS=("claude-code" "cursor")

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
  printf 'bunx is required. Install the Mise-managed Bun runtime first.\n' >&2
  exit 1
fi

CHECKOUT_DIRECTORIES=()

cleanup_checkouts() {
  local directory=""

  for directory in "${CHECKOUT_DIRECTORIES[@]-}"; do
    [[ -n "$directory" ]] && rm -rf "$directory"
  done
}

trap cleanup_checkouts EXIT

print_command() {
  local argument=""

  printf '  +'
  for argument in "$@"; do
    printf ' %q' "$argument"
  done
  printf '\n'
}

# The Skills CLI clones a source with `git clone --branch <ref>`, and git only
# accepts a branch or tag name there, never a commit SHA. Handing it a pinned
# tree URL therefore fails outright for every repository outside its own blob
# download allowlist. Fetching the exact commit here and passing the resulting
# local path keeps the commit pin and gives the CLI something it can read.
fetch_pinned_tree() {
  local owner_repo="$1"
  local commit="$2"
  local destination="$3"

  git init --quiet "$destination"
  git -C "$destination" remote add origin "https://github.com/${owner_repo}.git"
  git -C "$destination" fetch --quiet --depth 1 origin "$commit"
  git -C "$destination" checkout --quiet FETCH_HEAD
}

install_source() {
  local source_url="$1"
  local skill_names="$2"
  local agent=""
  local skill=""
  local owner_repo=""
  local commit=""
  local subpath=""
  local checkout_directory=""
  local skill_directory=""
  local -a command=()
  local -a skills=()

  if [[ ! "$source_url" =~ ^https://github\.com/([A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)/tree/([0-9a-f]{40})(/(.+))?$ ]]; then
    printf 'Source must be a GitHub tree URL pinned to a full commit SHA: %s\n' \
      "$source_url" >&2
    return 1
  fi

  owner_repo="${BASH_REMATCH[1]}"
  commit="${BASH_REMATCH[2]}"
  subpath="${BASH_REMATCH[4]}"

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
  done

  if [[ "$DRY_RUN" == true ]]; then
    print_command git fetch --depth 1 \
      "https://github.com/${owner_repo}.git" "$commit"
    checkout_directory="<checkout>"
  else
    checkout_directory="$(mktemp -d)"
    CHECKOUT_DIRECTORIES+=("$checkout_directory")
    fetch_pinned_tree "$owner_repo" "$commit" "$checkout_directory"
  fi

  skill_directory="$checkout_directory"
  if [[ -n "$subpath" ]]; then
    skill_directory="$checkout_directory/$subpath"
  fi

  if [[ "$DRY_RUN" != true && ! -d "$skill_directory" ]]; then
    printf 'Pinned commit %s has no directory %s\n' "$commit" "$subpath" >&2
    return 1
  fi

  command=(
    bunx
    --bun
    "skills@${SKILLS_CLI_VERSION}"
    add
    "$skill_directory"
    --global
    --yes
  )

  for skill in "${skills[@]}"; do
    command+=(--skill "$skill")
  done

  for agent in "${TARGET_AGENTS[@]}"; do
    command+=(--agent "$agent")
  done

  if [[ "$DRY_RUN" == true ]]; then
    print_command "${command[@]}"
  else
    DISABLE_TELEMETRY=1 "${command[@]}"
  fi
}

printf 'Installing pinned global agent skills for Claude Code and Cursor\n'

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

  if [[ ! "$source_url" =~ ^https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+/tree/[0-9a-f]{40}(/[A-Za-z0-9_.@/-]+)?$ ]]; then
    printf 'Source must be a GitHub tree URL pinned to a full commit SHA: %s\n' \
      "$source_url" >&2
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
  printf 'Would reconcile %d pinned skills from %d sources.\n' \
    "$skill_count" "$source_count"
else
  printf 'Reconciled %d pinned skills from %d sources.\n' \
    "$skill_count" "$source_count"
fi

# The NotebookLM skill ships inside the NotebookLM CLI package and is installed
# by that CLI, so it cannot be pinned through the skills inventory above.
printf '\nInstalling the NotebookLM skill through its own CLI\n'

if [[ "$DRY_RUN" != true ]] && ! command -v nlm >/dev/null 2>&1; then
  printf 'nlm was not found. Install the mise-managed NotebookLM CLI first.\n' >&2
  exit 1
fi

for agent in "${TARGET_AGENTS[@]}"; do
  if [[ "$DRY_RUN" == true ]]; then
    print_command nlm skill install "$agent" --level user
  else
    nlm skill install "$agent" --level user
  fi
done
