#!/usr/bin/env bash

# The manual coding agent gate of the managed setup, run as the first `final`
# bootstrap hook in mise.toml, after Homebrew installed every agent and before
# Herdr hooks them.
#
# Herdr can only install an integration once an agent has created its
# configuration directory, and that happens on the agent's first run. Signing in
# is interactive and personal, so this script never logs anybody in. It only
# blocks until every managed agent is set up, and verifies the result.
#
# Claude Code, Codex, and the Cursor CLI expose a non-interactive login check,
# so those are verified against real authentication. Oh My Pi and Pi keep their
# credentials in a vault with no stable probe, so those are verified against the
# directory Herdr needs, and the printed instruction covers the sign-in.

set -Eeuo pipefail

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "${REPO_ROOT}/scripts/lib.sh"

# Every managed coding agent, as `key|display name|command|sign-in instruction`.
readonly AGENTS=(
  "claude|Claude Code|claude|run \`claude\`, then sign in with /login"
  "codex|Codex|codex|run \`codex login\`"
  "cursor|Cursor CLI|cursor-agent|run \`cursor-agent login\`"
  "omp|Oh My Pi|omp|run \`omp\`, finish the onboarding and sign in, then leave with /exit"
  "pi|Pi|pi|run \`pi\`, sign in, then leave with /exit"
)

agent_field() {
  local entry="$1"
  local index="$2"

  cut -d '|' -f "$index" <<<"$entry"
}

agent_ready() {
  case "$1" in
    claude)
      jq -e '.oauthAccount' "$HOME/.claude.json"
      ;;
    codex)
      codex login status
      ;;
    cursor)
      cursor-agent status --format json | jq -e '.isAuthenticated == true'
      ;;
    omp)
      [[ -d "$HOME/.omp/agent" ]]
      ;;
    pi)
      jq -e 'length > 0' "$HOME/.pi/agent/auth.json"
      ;;
    *)
      return 1
      ;;
  esac >/dev/null 2>&1
}

# Names of the agents that still need a first run, newline separated.
pending_agents() {
  local entry=""
  local key=""

  for entry in "${AGENTS[@]}"; do
    key="$(agent_field "$entry" 1)"

    if ! agent_ready "$key"; then
      printf '%s\n' "$entry"
    fi
  done
}

print_pending_instructions() {
  local pending="$1"
  local entry=""

  manual_step "Sign in to the managed coding agents"

  printf '\n  Herdr installs its agent integrations right after this step, and\n'
  printf '  it can only hook an agent that has been started and signed in at\n'
  printf '  least once.\n'
  printf '\n  Still waiting on:\n'

  while IFS= read -r entry; do
    [[ -n "$entry" ]] || continue

    printf '\n  %s%s%s\n' "$BOLD" "$(agent_field "$entry" 2)" "$RESET"

    if ! command -v "$(agent_field "$entry" 3)" >/dev/null 2>&1; then
      printf '       %s is missing. Apply the Brewfile first.\n' \
        "$(agent_field "$entry" 3)"
      continue
    fi

    printf '       %s\n' "$(agent_field "$entry" 4)"
  done <<<"$pending"

  printf '\n  Use a second terminal window, the setup keeps waiting in this one.\n'
}

log "Checking the managed coding agents"

pending="$(pending_agents)"

# The block is reprinted on every round on purpose. It lists what is still
# pending, so a shorter list is the report on what the last round achieved.
while [[ -n "$pending" ]]; do
  print_pending_instructions "$pending"

  confirm_manual_step "mise run setup"

  pending="$(pending_agents)"
done

printf 'Every managed coding agent is signed in.\n'
