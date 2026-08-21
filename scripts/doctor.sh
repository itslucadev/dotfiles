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
  node \
  bun \
  pnpm \
  python \
  uv \
  ruff \
  pyright \
  biome \
  bat \
  eza \
  fd \
  portless \
  prettier \
  tailscale \
  gh \
  agent-browser \
  asc \
  axe \
  bfg \
  fallow \
  ffmpeg \
  gitleaks \
  linear \
  mole \
  resend \
  sentry-wizard \
  git \
  git-lfs \
  jq \
  mas \
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
  opencode \
  grok \
  code \
  cursor \
  tsc; do
  check_command "$command_name"
done

# Antidote ships no executable on PATH. It is a set of zsh functions that
# ~/.zshrc sources from this file, so the file is what tells us it is usable.
if [[ -r /opt/homebrew/opt/antidote/share/antidote/antidote.zsh ]]; then
  pass "Antidote is installed for zsh to source"
else
  fail "Antidote is missing at /opt/homebrew/opt/antidote/share/antidote/antidote.zsh"
fi

# mise is installed by bootstrap.sh from its own installer, never by Homebrew.
# A Homebrew copy would be removed by brew bundle cleanup mid-setup.
if [[ -x "$HOME/.local/bin/mise" ]]; then
  pass "mise is self-managed at ~/.local/bin/mise"
else
  fail "mise is not installed at ~/.local/bin/mise"
fi

if command -v brew >/dev/null 2>&1 && brew list --formula mise >/dev/null 2>&1; then
  fail "mise is installed through Homebrew and must be removed with brew uninstall mise"
else
  pass "mise is not installed through Homebrew"
fi

# The daily tool updater is a launchd agent, installed by the final bootstrap
# hook. `launchctl print` only succeeds for an agent that is actually loaded,
# which a plist on disk alone does not guarantee.
if launchctl print "gui/$(id -u)/com.phoenix-error.dotfiles.update-tools" >/dev/null 2>&1; then
  pass "Daily tool update agent is loaded"
else
  fail "Daily tool update agent is not loaded. Run mise run update:schedule"
fi

if launchctl print "gui/$(id -u)/com.phoenix-error.dotfiles.sync-omp-agent" >/dev/null 2>&1; then
  pass "Evening omp settings agent is loaded"
else
  fail "Evening omp settings agent is not loaded. Run mise run omp:schedule"
fi

if launchctl print "gui/$(id -u)/com.phoenix-error.dotfiles.ssh-agent" >/dev/null 2>&1; then
  pass "Delegated ssh-agent launchd unit is loaded"
else
  fail "Delegated ssh-agent launchd unit is not loaded. Run mise run ssh:agent"
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

# Homebrew 6 re-quarantines every cask download, and Sparkle updates do
# the same. The daily updater and `mise run apps:clear-quarantine` drop
# that flag. A leftover is a warning because an update can put it back
# between runs.
if command -v brew >/dev/null 2>&1 &&
  command -v jq >/dev/null 2>&1 &&
  [[ -x "$HOME/github/phoenix-error/dotfiles/scripts/clear-cask-quarantine.sh" ]]; then
  quarantined_casks=""
  while IFS= read -r cask_app; do
    [[ -n "$cask_app" && -e "$cask_app" ]] || continue
    if xattr -p com.apple.quarantine "$cask_app" >/dev/null 2>&1; then
      quarantined_casks+="${quarantined_casks:+, }$(basename "$cask_app")"
    fi
  done < <("$HOME/github/phoenix-error/dotfiles/scripts/clear-cask-quarantine.sh" --list)

  if [[ -z "$quarantined_casks" ]]; then
    pass "Homebrew cask apps are not Gatekeeper-quarantined"
  else
    warn "Quarantined Homebrew cask apps: ${quarantined_casks}. Run mise run apps:clear-quarantine"
  fi
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

# The Dock is the one managed thing no bootstrap phase converges, because a
# rearranged Dock is work that a converging phase would silently undo. This
# report is what replaces that automation: it says which of the two directions
# is out of date, and the person decides which one is right. Drift is the normal
# state of a Mac whose Dock was rearranged an hour ago, so it warns.
dock_manifest="$HOME/github/phoenix-error/dotfiles/dock.txt"
dock_script="$HOME/github/phoenix-error/dotfiles/scripts/sync-dock.sh"

if [[ -r "$dock_manifest" && -x "$dock_script" ]]; then
  if "$dock_script" export --print 2>/dev/null | diff -q "$dock_manifest" - >/dev/null 2>&1; then
    pass "The Dock matches dock.txt"
  else
    warn "The Dock differs from dock.txt. Run mise run dock:apply or mise run dock:export"
  fi
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

if command -v jq >/dev/null 2>&1 &&
  jq -e '
    .enabledPlugins["composio@composio"] == true and
    .extraKnownMarketplaces.composio.source.url == "https://github.com/ComposioHQ/composio-plugin-cc.git"
  ' "$HOME/.claude/settings.json" >/dev/null 2>&1; then
  pass "Claude Composio plugin is enabled"
else
  fail "Claude Composio plugin is missing"
fi

if command -v jq >/dev/null 2>&1 &&
  jq -e '
    .enabledPlugins["codex@openai-codex"] == true and
    .extraKnownMarketplaces["openai-codex"].source.repo == "openai/codex-plugin-cc"
  ' "$HOME/.claude/settings.json" >/dev/null 2>&1; then
  pass "Claude Codex plugin is enabled"
else
  fail "Claude Codex plugin is missing"
fi

for application_name in \
  "AltTab" \
  "Android Studio" \
  "Aqua Voice" \
  "ChatGPT" \
  "Claude" \
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
  "ProtonVPN" \
  "Raycast" \
  "RocketSim" \
  "Spark Desktop" \
  "Tailscale" \
  "TextMate" \
  "T3 Code (Alpha)" \
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
  "Raycast Beta" \
  "Recordly"; do
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

# mise.toml owns the two portless variables, but the trust store entry, the
# launchd service, and the Tailscale certificate setting are machine state that
# only the manual steps in setup-guide.html can create. They are warnings, not
# failures, because a fresh Mac reaches this point before those steps have run.
if [[ "${PORTLESS_TLD:-}" == "dev" ]]; then
  pass "Portless serves local development URLs under .dev"
else
  fail "PORTLESS_TLD is not set to dev"
fi

if [[ "${PORTLESS_TAILSCALE:-}" == "1" ]]; then
  pass "Portless publishes apps to the tailnet"
else
  fail "PORTLESS_TAILSCALE is not set to 1"
fi

# Funnel is the public-internet variant of the same sharing. It is left unset on
# purpose, so an inherited value from a shell or .env file is worth reporting.
if [[ -n "${PORTLESS_FUNNEL:-}" ]]; then
  warn "PORTLESS_FUNNEL is set, which would expose dev servers to the public internet"
else
  pass "Tailscale Funnel stays disabled for portless"
fi

if command -v portless >/dev/null 2>&1; then
  portless_service_status="$(portless service status 2>/dev/null || true)"

  if grep -q '^  Installed: yes' <<<"$portless_service_status"; then
    pass "Portless startup service is installed"
  else
    warn "Portless startup service is missing. Run portless service install --tld dev"
  fi

  if grep -q '^  TLDs:.*\.dev' <<<"$portless_service_status"; then
    pass "Portless startup service serves .dev"
  else
    warn "Portless startup service does not serve .dev. Reinstall it with --tld dev"
  fi
fi

# CertDomains is only populated once HTTPS certificates are enabled for the
# tailnet, and portless aborts before starting a dev server without them.
if command -v tailscale >/dev/null 2>&1; then
  if tailscale status --json 2>/dev/null | grep -q '"CertDomains": \['; then
    pass "Tailscale HTTPS certificates are enabled"
  else
    warn "Tailscale HTTPS certificates are disabled, so portless cannot share apps. Enable them at https://login.tailscale.com/admin/dns"
  fi
fi

for agent_wrapper in gh-axi lavish-axi chrome-devtools-axi ctx7 nlm composio; do
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

  for herdr_integration in claude codex cursor omp opencode grok; do
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

# Commit signing stays optional and unchecked. Nothing here depends on it,
# GitHub accepts unsigned pushes, and the only thing it buys is the Verified
# badge, so the setup guide documents it as an optional step instead. The key
# below is checked for authentication alone, which is what the bootstrap gate
# and every `git push` actually need.
if [[ -f "$HOME/.ssh/id_ed25519" && -f "$HOME/.ssh/id_ed25519.pub" ]] &&
  ssh-keygen -lf "$HOME/.ssh/id_ed25519.pub" >/dev/null 2>&1 &&
  [[ "$(awk 'NR == 1 { print $1 }' "$HOME/.ssh/id_ed25519.pub")" == "ssh-ed25519" ]]; then
  pass "GitHub SSH key pair exists locally"
else
  warn "Create an Ed25519 key at ~/.ssh/id_ed25519 for GitHub authentication"
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

# Coding agents must authenticate through ssh-agent. The socket is a signing
# capability. If it is missing they fall back to reading the private key,
# which is exactly the secret we do not want in an agent session.
if [[ -S "$HOME/.ssh/agent.sock" ]] &&
  SSH_AUTH_SOCK="$HOME/.ssh/agent.sock" ssh-add -l >/dev/null 2>&1; then
  pass "Delegated ssh-agent socket can sign without the private key"
else
  warn "Run mise run ssh:agent and ssh-add --apple-use-keychain ~/.ssh/id_ed25519"
fi

ssh_identity_agent="$(
  ssh -G github.com 2>/dev/null |
    awk '$1 == "identityagent" { print $2; exit }'
)"

if [[ "$ssh_identity_agent" == *agent.sock ]]; then
  pass "SSH IdentityAgent points at the delegated socket"
else
  warn "Point IdentityAgent at ~/.ssh/agent.sock so agents do not need SSH_AUTH_SOCK"
fi

if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  pass "GitHub CLI is authenticated"
else
  warn "GitHub CLI is not authenticated"
fi

printf '\nSummary: %d failure(s), %d warning(s)\n' "$failures" "$warnings"
printf 'Open setup-guide.html for the remaining manual permissions and logins.\n'

if [[ "$STRICT" == true && "$failures" -gt 0 ]]; then
  exit 1
fi

exit 0
