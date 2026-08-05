#!/usr/bin/env bash

set -uo pipefail

failures=0
warnings=0
STRICT=false

usage() {
  printf 'Usage: %s [--strict]\n' "${0##*/}"
}

for argument in "$@"; do
  case "$argument" in
    --strict)
      STRICT=true
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

check_manual_app() {
  local application_name="$1"
  if [[ -d "/Applications/${application_name}.app" ]]; then
    pass "Manual application installed: $application_name"
  else
    warn "Manual application missing: $application_name"
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
  antidote \
  node \
  bun \
  python \
  uv \
  ruff \
  pyright \
  biome \
  bat \
  eza \
  fd \
  prettier \
  gh \
  git \
  git-lfs \
  jq \
  mas \
  posthog-cli \
  rg \
  sentry \
  yt-dlp \
  zoxide \
  java \
  watchman \
  pod \
  maestro \
  fastlane \
  lazygit \
  fzf \
  herdr \
  starship \
  tmux \
  agent-device \
  argent \
  eas \
  react-doctor \
  claude \
  codex \
  cursor-agent \
  omp \
  pi \
  code \
  cursor \
  tsc; do
  check_command "$command_name"
done

# mise is installed by bootstrap.sh from its own installer, never by Homebrew.
# A Homebrew copy would be removed by brew bundle cleanup mid-setup.
if [[ -x "$HOME/.local/bin/mise" ]]; then
  pass "mise is self-managed at ~/.local/bin/mise"
else
  fail "mise is missing at ~/.local/bin/mise"
fi

if command -v brew >/dev/null 2>&1 && brew list --formula mise >/dev/null 2>&1; then
  fail "mise is installed through Homebrew and must be removed with brew uninstall mise"
else
  pass "mise is not installed through Homebrew"
fi

if command -v brew >/dev/null 2>&1 &&
  brew bundle check --no-upgrade \
    --file "$HOME/github/phoenix-error/dotfiles/Brewfile" >/dev/null 2>&1; then
  pass "Homebrew formulae and casks satisfy Brewfile"
else
  fail "Homebrew formulae or casks do not satisfy Brewfile"
fi

if command -v brew >/dev/null 2>&1 &&
  brew bundle cleanup \
    --formula \
    --cask \
    --tap \
    --file "$HOME/github/phoenix-error/dotfiles/Brewfile" \
    </dev/null >/dev/null 2>&1; then
  pass "No unmanaged Homebrew formulae, casks, or taps are installed"
else
  fail "Unmanaged Homebrew formulae, casks, or taps are installed"
fi

if command -v mise >/dev/null 2>&1 &&
  mise bootstrap dotfiles status --missing >/dev/null 2>&1; then
  pass "Managed dotfiles are in sync"
else
  fail "Managed dotfiles are missing or differ"
fi

if command -v mise >/dev/null 2>&1 &&
  mise bootstrap macos defaults status --missing >/dev/null 2>&1; then
  pass "Managed macOS defaults are in sync"
else
  fail "Managed macOS defaults are missing or differ"
fi

if command -v python >/dev/null 2>&1 &&
  [[ "$(python -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null)" == "3.12" ]]; then
  pass "Managed Python version is 3.12"
else
  fail "Managed Python version is not 3.12"
fi

if [[ -n "${JAVA_HOME:-}" && -x "$JAVA_HOME/bin/java" ]] &&
  java -version 2>&1 | head -n 1 | grep -Eq 'version "17\.|openjdk version "17\.'; then
  pass "Managed Zulu JDK 17 and JAVA_HOME are active"
else
  fail "Managed Zulu JDK 17 or JAVA_HOME is unavailable"
fi

if find "$HOME/Library/Fonts" /Library/Fonts \
  -maxdepth 1 \
  -type f \
  -iname '*Hack*Nerd*Font*' \
  -print -quit 2>/dev/null | grep -q .; then
  pass "Hack Nerd Font is installed"
else
  fail "Hack Nerd Font is missing"
fi

if [[ "$(defaults read com.apple.HIToolbox AppleFnUsageType 2>/dev/null)" == "0" ]]; then
  pass "Fn or Globe is free for Aqua Voice"
else
  fail "Fn or Globe still has a native macOS action"
fi

if command -v jq >/dev/null 2>&1 &&
  jq -e '
    .permissions.defaultMode == "auto" and
    .env.ENABLE_LSP_TOOL == "1" and
    .teammateMode == "tmux" and
    .enabledPlugins["pyright-lsp@claude-plugins-official"] == true and
    .enabledPlugins["typescript-lsp@claude-plugins-official"] == true
  ' "$HOME/.claude/settings.json" >/dev/null 2>&1; then
  pass "Claude Auto mode, Tmux teams, and LSP plugins are configured"
else
  fail "Claude Auto mode, Tmux teams, or LSP plugins differ"
fi

for application_name in \
  "AltTab" \
  "Android Studio" \
  "Aqua Voice" \
  "ChatGPT" \
  "Claude" \
  "CleanMyMac_5" \
  "CleanShot X" \
  "CurseForge" \
  "Cursor" \
  "Dia" \
  "Expo Orbit" \
  "FluxMarkdown" \
  "Folder Quick Look" \
  "Ghostty" \
  "Google Chrome" \
  "Helm" \
  "Hoppscotch" \
  "IINA" \
  "ImageOptim" \
  "Linear" \
  "LocalSend" \
  "Minecraft" \
  "MultiViewer" \
  "Obsidian" \
  "Obsidian Web Clipper" \
  "OpenUsage" \
  "ProtonVPN" \
  "Raycast" \
  "Raycast Beta" \
  "RocketSim" \
  "Spark Desktop" \
  "Tailscale" \
  "TextMate" \
  "Tower" \
  "Visual Studio Code" \
  "Vorssaint" \
  "WezTerm" \
  "WhatsApp" \
  "YouTube Music" \
  "Xcode"; do
  check_app "$application_name"
done

for application_name in \
  "Actions" \
  "Timepage"; do
  check_app "$application_name"
done

for application_name in \
  "Maestro Studio" \
  "Recordly" \
  "SimCam"; do
  check_manual_app "$application_name"
done

if [[ "${ANDROID_HOME:-}" == "$HOME/Library/Android/sdk" ]]; then
  pass "ANDROID_HOME points to the standard macOS Android SDK"
else
  fail "ANDROID_HOME does not point to ~/Library/Android/sdk"
fi

if [[ ":${PATH:-}:" == *":$HOME/Library/Android/sdk/emulator:"* ]] &&
  [[ ":${PATH:-}:" == *":$HOME/Library/Android/sdk/platform-tools:"* ]]; then
  pass "Android emulator and platform-tools directories are on PATH"
else
  fail "Android emulator or platform-tools directory is missing from PATH"
fi

if [[ -d "$HOME/Library/Android/sdk" ]]; then
  pass "Android SDK was installed manually through Android Studio"
else
  warn "Complete Android Studio onboarding to install the Android SDK"
fi

for agent_wrapper in gh-axi lavish-axi chrome-devtools-axi ctx7 nlm; do
  if command -v "$agent_wrapper" >/dev/null 2>&1; then
    pass "Preferred agent CLI available: $agent_wrapper"
  else
    fail "Preferred agent CLI missing: $agent_wrapper"
  fi
done

if [[ -f "$HOME/.claude/rules/context7.md" ]]; then
  pass "Managed Claude rule is applied: context7"
else
  fail "Managed Claude rule is missing: ~/.claude/rules/context7.md"
fi

# Herdr reports every integration it knows. An agent that was never started has
# no configuration directory, so its integration stays uninstalled until
# `mise run agents:login` and `mise run agents:herdr` have both run.
if command -v herdr >/dev/null 2>&1; then
  herdr_status="$(herdr integration status 2>/dev/null || true)"

  for herdr_integration in claude codex cursor omp pi; do
    if grep -Eq "^${herdr_integration}: (current|outdated)" <<<"$herdr_status"; then
      pass "Herdr integration installed: $herdr_integration"
    else
      warn "Herdr integration missing: $herdr_integration. Sign the agent in, then run mise run agents:herdr"
    fi
  done
fi

local_override_found=false
for local_override in \
  "$HOME/.claude/settings.local.json" \
  "$HOME/.config/mise/config.local.toml"; do
  if [[ -e "$local_override" ]]; then
    warn "Unmanaged local override file exists: ${local_override/#$HOME/\~}"
    local_override_found=true
  fi
done

if [[ "$local_override_found" == false ]]; then
  pass "No local override files are present"
fi

if xcode-select -p 2>/dev/null | grep -Fq "/Applications/Xcode.app/"; then
  pass "Xcode is the active developer directory"
else
  warn "Launch Xcode once so it becomes the active developer directory"
fi

if git config --global user.name >/dev/null 2>&1 &&
  git config --global user.email >/dev/null 2>&1; then
  pass "Global Git identity is configured"
else
  warn "Global Git name or email is missing"
fi

if [[ "$(git config --global --bool commit.gpgsign 2>/dev/null)" == "true" ]] &&
  git config --global user.signingkey >/dev/null 2>&1; then
  pass "Git SSH commit signing is enabled"
else
  warn "Git SSH commit signing is not enabled with a signing key"
fi

if [[ -f "$HOME/.ssh/id_ed25519" && -f "$HOME/.ssh/id_ed25519.pub" ]] &&
  ssh-keygen -lf "$HOME/.ssh/id_ed25519.pub" >/dev/null 2>&1 &&
  [[ "$(awk 'NR == 1 { print $1 }' "$HOME/.ssh/id_ed25519.pub")" == "ssh-ed25519" ]]; then
  pass "GitHub SSH key pair exists locally"
else
  warn "Create an Ed25519 key at ~/.ssh/id_ed25519 for GitHub authentication and signing"
fi

if [[ -f "$HOME/.ssh/allowed_signers" ]]; then
  pass "SSH allowed signers file exists"
else
  warn "Create ~/.ssh/allowed_signers before enabling commit signing"
fi

# ~/.ssh/config is configured by hand. Asking ssh for the options it would
# actually use covers a Host * block as well as a github.com specific one,
# which grepping the file would not. Without any configuration ssh reports
# addkeystoagent as false and offers every default key instead.
ssh_add_keys_to_agent="$(
  ssh -G github.com 2>/dev/null |
    awk '$1 == "addkeystoagent" { print $2; exit }'
)"

if [[ -n "$ssh_add_keys_to_agent" && "$ssh_add_keys_to_agent" != "false" ]]; then
  pass "SSH loads the GitHub key into the agent"
else
  warn "Set AddKeysToAgent and UseKeychain in ~/.ssh/config so the passphrase is asked once"
fi

if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  pass "GitHub CLI is authenticated"
else
  warn "GitHub CLI is not authenticated"
fi

printf '\nSummary: %d failure(s), %d warning(s)\n' "$failures" "$warnings"
printf 'Open docs/setup-guide.html for the remaining manual permissions and logins.\n'

if [[ "$STRICT" == true && "$failures" -gt 0 ]]; then
  exit 1
fi

exit 0
