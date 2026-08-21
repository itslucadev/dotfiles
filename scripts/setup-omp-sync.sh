#!/usr/bin/env bash

# Installs the launchd agent that runs scripts/sync-omp-agent-settings.sh
# every evening, as a `final` bootstrap hook in mise.toml and by hand via
# `mise run omp:schedule`.
#
# launchd is used instead of cron because it handles sleep correctly: a Mac
# that is asleep at the scheduled time runs the job at the next wake, while
# cron silently skips it. The plist is rendered rather than linked as a
# managed dotfile, because installing it takes a `launchctl bootstrap` call
# that the dotfiles phase cannot express.
#
# The agent has no RunAtLoad, so installing or reinstalling the schedule
# never writes the snapshot by itself. The first run happens at the next 20:00.

set -Eeuo pipefail

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "${REPO_ROOT}/scripts/lib.sh"

readonly AGENT_LABEL="com.phoenix-error.dotfiles.sync-omp-agent"
readonly AGENT_PLIST="$HOME/Library/LaunchAgents/${AGENT_LABEL}.plist"
readonly AGENT_LOG="$HOME/Library/Logs/dotfiles-omp-sync.log"

log "Installing the evening omp settings check"

mkdir -p "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"

cat >"$AGENT_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>${AGENT_LABEL}</string>
	<key>ProgramArguments</key>
	<array>
		<string>/bin/bash</string>
		<string>${REPO_ROOT}/scripts/sync-omp-agent-settings.sh</string>
	</array>
	<key>StartCalendarInterval</key>
	<dict>
		<key>Hour</key>
		<integer>20</integer>
		<key>Minute</key>
		<integer>0</integer>
	</dict>
	<key>StandardOutPath</key>
	<string>${AGENT_LOG}</string>
	<key>StandardErrorPath</key>
	<string>${AGENT_LOG}</string>
</dict>
</plist>
PLIST

# Reinstalling must pick up a changed plist, and launchd only rereads it on a
# fresh bootstrap. The bootout is allowed to fail when the agent was never
# loaded before.
launchctl bootout "gui/$(id -u)/${AGENT_LABEL}" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$AGENT_PLIST"

printf 'Scheduled daily at 20:00. Log: %s\n' "$AGENT_LOG"
