#!/usr/bin/env bash

# Keeps ssh-agent listening on ~/.ssh/agent.sock and points ~/.ssh/config at
# that socket. Coding agents then inherit a signing capability and never read
# the private key.
#
# launchd is used instead of `eval "$(ssh-agent -s)"` because a login-shell
# agent dies with that shell, and Aqua's launchd socket is not exported into
# SSH sessions. A stable path is what SSH logins, GUI terminals, and coding
# agents can all share.
#
# Installed as a `final` bootstrap hook and by hand via `mise run ssh:agent`.

set -Eeuo pipefail

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "${REPO_ROOT}/scripts/lib.sh"

readonly AGENT_LABEL="com.phoenix-error.dotfiles.ssh-agent"
readonly AGENT_PLIST="$HOME/Library/LaunchAgents/${AGENT_LABEL}.plist"
readonly AGENT_LOG="$HOME/Library/Logs/dotfiles-ssh-agent.log"
readonly AGENT_SOCKET="$HOME/.ssh/agent.sock"
readonly SSH_CONFIG="$HOME/.ssh/config"
readonly SSH_CONFIG_MARKER="phoenix-error ssh-agent"

log "Installing the delegated ssh-agent socket"

mkdir -p "$HOME/.ssh" "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"
chmod 700 "$HOME/.ssh"

cat >"$AGENT_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>${AGENT_LABEL}</string>
	<key>ProgramArguments</key>
	<array>
		<string>/usr/bin/ssh-agent</string>
		<string>-D</string>
		<string>-a</string>
		<string>${AGENT_SOCKET}</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
	<key>KeepAlive</key>
	<true/>
	<key>StandardOutPath</key>
	<string>${AGENT_LOG}</string>
	<key>StandardErrorPath</key>
	<string>${AGENT_LOG}</string>
</dict>
</plist>
PLIST

if SSH_AUTH_SOCK="$AGENT_SOCKET" ssh-add -l >/dev/null 2>&1 ||
  SSH_AUTH_SOCK="$AGENT_SOCKET" ssh-add -l 2>&1 | grep -Fq 'The agent has no identities'; then
  printf 'Socket already live at %s. launchd takes over on the next login.\n' "$AGENT_SOCKET"
else
  launchctl bootout "gui/$(id -u)/${AGENT_LABEL}" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" "$AGENT_PLIST"
  printf 'Started ssh-agent on %s. Log: %s\n' "$AGENT_SOCKET" "$AGENT_LOG"
fi

if [[ -f "$SSH_CONFIG" ]] && grep -Fq "$SSH_CONFIG_MARKER" "$SSH_CONFIG"; then
  printf 'IdentityAgent is already declared in %s\n' "$SSH_CONFIG"
else
  mkdir -p "$(dirname "$SSH_CONFIG")"
  touch "$SSH_CONFIG"
  chmod 600 "$SSH_CONFIG"
  {
    printf '# --- begin %s ---\n' "$SSH_CONFIG_MARKER"
    printf '# Coding agents authenticate through ssh-agent. The socket is a signing\n'
    printf '# capability, not a secret. They must never read ~/.ssh/id_ed25519.\n'
    printf 'Match exec "test -S ~/.ssh/agent.sock"\n'
    printf '  IdentityAgent ~/.ssh/agent.sock\n'
    printf '# --- end %s ---\n\n' "$SSH_CONFIG_MARKER"
    cat "$SSH_CONFIG"
  } >"${SSH_CONFIG}.tmp"
  mv "${SSH_CONFIG}.tmp" "$SSH_CONFIG"
  chmod 600 "$SSH_CONFIG"
  printf 'Pointed %s at %s\n' "$SSH_CONFIG" "$AGENT_SOCKET"
fi

if SSH_AUTH_SOCK="$AGENT_SOCKET" ssh-add -l >/dev/null 2>&1; then
  printf 'ssh-agent can sign. Coding agents do not need the private key.\n'
else
  printf 'Load the key once from a GUI terminal:\n'
  printf '  ssh-add --apple-use-keychain ~/.ssh/id_ed25519\n'
fi
