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

check_editor_extensions() {
  local editor="$1"
  local extension_file="$2"
  local installed_extensions=""
  local extension=""

  if ! command -v "$editor" >/dev/null 2>&1; then
    fail "Cannot check extensions, editor command missing: $editor"
    return
  fi

  # A failing --list-extensions would otherwise yield an empty list, which reads
  # as "nothing is installed" and reports every extension as missing without
  # ever showing the real reason.
  if ! installed_extensions="$("$editor" --list-extensions 2>&1)"; then
    fail "Could not list installed extensions for $editor: $installed_extensions"
    return
  fi

  installed_extensions="$(printf '%s' "$installed_extensions" | tr '[:upper:]' '[:lower:]')"

  while IFS= read -r extension || [[ -n "$extension" ]]; do
    if [[ -z "$extension" || "$extension" == \#* ]]; then
      continue
    fi

    if grep -Fxiq "$extension" <<<"$installed_extensions"; then
      pass "$editor extension installed: $extension"
    else
      fail "$editor extension missing: $extension"
    fi
  done <"$extension_file"
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
  infisical \
  starship \
  tmux \
  agent-device \
  argent \
  eas \
  react-doctor \
  claude \
  code \
  cursor \
  tsc; do
  check_command "$command_name"
done

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
  "Caffeine" \
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
  "GatherOS" \
  "Maestro Studio" \
  "Recordly" \
  "SimCam"; do
  check_manual_app "$application_name"
done

check_editor_extensions \
  code \
  "$HOME/github/phoenix-error/dotfiles/home/.config/editors/extensions.txt"
check_editor_extensions \
  code \
  "$HOME/github/phoenix-error/dotfiles/home/.config/editors/vscode/extensions.txt"
check_editor_extensions \
  cursor \
  "$HOME/github/phoenix-error/dotfiles/home/.config/editors/extensions.txt"
check_editor_extensions \
  cursor \
  "$HOME/github/phoenix-error/dotfiles/home/.config/editors/cursor/extensions.txt"

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

if [[ -f "$HOME/.claude/hooks/herdr-agent-state.sh" ]]; then
  pass "Herdr installed its Claude Code integration"
else
  warn "Run mise run agents:herdr to install the Herdr agent integrations"
fi

local_override_found=false
for local_override in \
  "$HOME/.claude/settings.local.json" \
  "$HOME/.gitconfig.local" \
  "$HOME/.ssh/config.local" \
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

if [[ "$(git config --global --bool commit.gpgsign 2>/dev/null)" == "true" ]] &&
  git config --global user.signingkey >/dev/null 2>&1; then
  pass "Git SSH commit signing is enabled"
else
  warn "Git SSH commit signing is not enabled with a signing key"
fi

github_ssh_status="$(
  "$HOME/github/phoenix-error/dotfiles/scripts/setup-github-ssh.sh" \
    --status 2>&1 || true
)"

if grep -Fq 'GitHub SSH key is configured locally.' <<<"$github_ssh_status"; then
  pass "GitHub SSH key is configured locally"
else
  warn "GitHub SSH key or allowed signers file is missing"
fi

if ssh -G github.com >/dev/null 2>&1; then
  pass "SSH configuration is valid for GitHub"
else
  fail "SSH configuration is invalid for GitHub"
fi

if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  pass "GitHub CLI is authenticated"
else
  warn "GitHub CLI is not authenticated"
fi

if grep -Fq \
  'GitHub SSH key is registered for authentication and signing.' \
  <<<"$github_ssh_status"; then
  pass "GitHub SSH key is registered for authentication and signing"
else
  warn "GitHub SSH authentication or signing registration is incomplete"
fi

if command -v infisical >/dev/null 2>&1 &&
  infisical login status >/dev/null 2>&1; then
  pass "Infisical CLI is authenticated"
else
  warn "Infisical CLI is not authenticated"
fi

printf '\nSummary: %d failure(s), %d warning(s)\n' "$failures" "$warnings"
printf 'Review the manual checklist in README.md for permissions and logins.\n'

if [[ "$STRICT" == true && "$failures" -gt 0 ]]; then
  exit 1
fi

exit 0
