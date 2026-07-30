#!/usr/bin/env bash

set -uo pipefail

failures=0
warnings=0

pass() {
  printf 'PASS  %s\n' "$1"
}

warn() {
  printf 'WARN  %s\n' "$1"
  warnings=$((warnings + 1))
}

fail() {
  printf 'FAIL  %s\n' "$1"
  failures=$((failures + 1))
}

check_command() {
  local command_name="$1"
  if command -v "$command_name" >/dev/null 2>&1; then
    pass "Command available: $command_name"
  else
    fail "Command missing: $command_name"
  fi
}

check_app() {
  local application_name="$1"
  if [[ -d "/Applications/${application_name}.app" ]]; then
    pass "Application installed: $application_name"
  else
    fail "Application missing: $application_name"
  fi
}

printf 'Mac setup doctor\n\n'

if [[ "$(uname -s)" == "Darwin" && "$(uname -m)" == "arm64" ]]; then
  pass "Apple Silicon macOS host"
else
  fail "Expected an Apple Silicon macOS host"
fi

for command_name in \
  brew \
  mise \
  node \
  bun \
  gh \
  java \
  watchman \
  pod \
  nvim \
  lazygit \
  fzf \
  starship \
  agent-device \
  argent \
  eas \
  react-doctor \
  claude \
  codex \
  tsc; do
  check_command "$command_name"
done

for application_name in \
  "AltTab" \
  "Android Studio" \
  "Aqua Voice" \
  "Caffeine" \
  "CleanMyMac" \
  "CleanShot X" \
  "ProtonVPN" \
  "Raycast" \
  "Raycast Beta" \
  "RocketSim" \
  "Tailscale" \
  "WezTerm" \
  "Xcode"; do
  check_app "$application_name"
done

if [[ -d "$HOME/Library/Android/sdk" ]]; then
  pass "Android SDK directory exists"
else
  warn "Android SDK is not configured yet"
fi

if xcode-select -p 2>/dev/null | grep -Fq "/Applications/Xcode.app/"; then
  pass "Stable Xcode is the active developer directory"
else
  warn "Select stable Xcode with xcode-select after its first launch"
fi

if git config --global user.name >/dev/null 2>&1 &&
  git config --global user.email >/dev/null 2>&1; then
  pass "Global Git identity is configured"
else
  warn "Global Git name or email is missing"
fi

if find "$HOME/.ssh" -maxdepth 1 -type f -name '*.pub' -print -quit 2>/dev/null | grep -q .; then
  pass "At least one SSH public key exists"
else
  warn "No SSH public key was found"
fi

if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  pass "GitHub CLI is authenticated"
else
  warn "GitHub CLI is not authenticated"
fi

printf '\nSummary: %d failure(s), %d warning(s)\n' "$failures" "$warnings"
printf 'Review the manual checklist in README.md for permissions and logins.\n'

if [[ "${1:-}" == "--strict" && "$failures" -gt 0 ]]; then
  exit 1
fi

exit 0
