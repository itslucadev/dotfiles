#!/usr/bin/env bash

set -Eeuo pipefail

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

export HOMEBREW_NO_AUTO_UPDATE=1

cd "$REPO_ROOT"

printf 'Checking shell syntax\n'
while IFS= read -r script; do
  bash -n "$script"
done < <(find . -path './.git' -prune -o -path './.worktrees' -prune -o -name '*.sh' -type f -print)
zsh -n home/.zprofile
zsh -n home/.zshrc

printf 'Checking TOML syntax\n'
toml_checked=false
for python_command in python3.14 python3.13 python3.12 python3.11 python3; do
  if command -v "$python_command" >/dev/null 2>&1 &&
    "$python_command" -c 'import tomllib' >/dev/null 2>&1; then
    "$python_command" - <<'PY'
from pathlib import Path
import tomllib

for path in sorted(Path(".").glob("*.toml")):
    with path.open("rb") as file:
        tomllib.load(file)
PY
    toml_checked=true
    break
  fi
done

if [[ "$toml_checked" != true ]] && command -v mise >/dev/null 2>&1; then
  MISE_SAFE=1 mise config ls >/dev/null
  toml_checked=true
fi

if [[ "$toml_checked" != true ]]; then
  printf 'No TOML parser is available.\n' >&2
  exit 1
fi

printf 'Checking Brewfiles\n'
if command -v brew >/dev/null 2>&1; then
  brew bundle list --all --file Brewfile >/dev/null
  brew bundle list --all --file Brewfile.mas >/dev/null
fi

printf 'Checking executable files\n'
for executable in \
  bootstrap.sh \
  scripts/configure-macos.sh \
  scripts/doctor.sh \
  scripts/install-agent-skills.sh \
  scripts/install-editor-extensions.sh \
  scripts/install-mas-apps.sh \
  scripts/install-raycast-beta.sh \
  scripts/setup-github-ssh.sh \
  tests/test.sh; do
  [[ -x "$executable" ]]
done

printf 'Checking managed configuration files\n'
for managed_file in \
  home/.claude/settings.json \
  home/.claude/statusline.ts \
  home/.config/editors/extensions.txt \
  home/.config/editors/cursor/extensions.txt \
  home/.config/editors/cursor/settings.json \
  home/.config/editors/vscode/extensions.txt \
  home/.config/editors/vscode/settings.json \
  home/.config/git/ignore \
  home/.config/ghostty/config.ghostty \
  home/.config/herdr/config.toml \
  home/.config/skills/default-skills.txt \
  home/.config/starship.toml \
  home/.config/wezterm/wezterm.lua \
  home/.gitconfig \
  home/.ssh/config \
  home/AGENTS.md \
  home/.zprofile \
  home/.zsh_plugins.txt \
  home/.zshrc; do
  [[ -f "$managed_file" ]]
done

printf 'Checking JSON syntax\n'
if command -v jq >/dev/null 2>&1; then
  jq empty home/.claude/settings.json
  jq empty home/.config/editors/cursor/settings.json
  jq empty home/.config/editors/vscode/settings.json
else
  "$python_command" -m json.tool home/.claude/settings.json >/dev/null
  "$python_command" -m json.tool home/.config/editors/cursor/settings.json >/dev/null
  "$python_command" -m json.tool home/.config/editors/vscode/settings.json >/dev/null
fi

if command -v bun >/dev/null 2>&1; then
  typescript_output="$(mktemp)"
  bun build home/.claude/statusline.ts \
    --target=bun \
    --outfile="$typescript_output" \
    >/dev/null
  rm -f "$typescript_output"
fi

printf 'Checking dry-run paths\n'
./bootstrap.sh --dry-run >/dev/null
./scripts/configure-macos.sh --dry-run >/dev/null
./scripts/doctor.sh --help >/dev/null
./scripts/install-agent-skills.sh --dry-run >/dev/null
./scripts/install-editor-extensions.sh --dry-run >/dev/null
./scripts/install-mas-apps.sh --dry-run >/dev/null
./scripts/install-raycast-beta.sh --dry-run >/dev/null

printf 'Checking isolated Mac App Store interaction gates\n'
mas_gate_bin="$(mktemp -d)"
mas_gate_output="$(mktemp)"

cat >"$mas_gate_bin/brew" <<'EOF'
#!/usr/bin/env bash

if [[ "$MAS_TEST_RESULT" == "manual" ]]; then
  printf 'Error: Not signed in to the App Store.\n' >&2
  exit 1
fi

if [[ "$MAS_TEST_RESULT" == "generic" ]]; then
  printf 'Error: Network connection failed.\n' >&2
  exit 1
fi

exit 0
EOF
chmod +x "$mas_gate_bin/brew"

set +e
MAS_TEST_RESULT=manual \
  PATH="$mas_gate_bin:$PATH" \
  ./scripts/install-mas-apps.sh </dev/null \
  >"$mas_gate_output" 2>&1
mas_gate_status=$?
set -e
[[ "$mas_gate_status" -eq 2 ]]
grep -Fq 'Manual action required.' "$mas_gate_output"
grep -Fq 'mise run apps:mas' "$mas_gate_output"
grep -Fq './bootstrap.sh' "$mas_gate_output"

set +e
MAS_TEST_RESULT=generic \
  PATH="$mas_gate_bin:$PATH" \
  ./scripts/install-mas-apps.sh </dev/null \
  >"$mas_gate_output" 2>&1
mas_gate_status=$?
set -e
[[ "$mas_gate_status" -eq 1 ]]
grep -Fq 'without a recognized login or claim error' "$mas_gate_output"

rm -rf "$mas_gate_bin"
rm -f "$mas_gate_output"

github_ssh_test_home="$(mktemp -d)"
github_ssh_dry_run="$(mktemp)"
HOME="$github_ssh_test_home" ./scripts/setup-github-ssh.sh --dry-run \
  >"$github_ssh_dry_run"
grep -Fq 'ssh-keygen -t ed25519' "$github_ssh_dry_run"
grep -Fq 'ssh-add --apple-use-keychain' "$github_ssh_dry_run"
grep -Fq 'gh ssh-key add' "$github_ssh_dry_run"
grep -Fq -- '--type authentication' "$github_ssh_dry_run"
grep -Fq -- '--type signing' "$github_ssh_dry_run"
grep -Fq 'gh auth login' "$github_ssh_dry_run"
grep -Fq 'gh auth refresh' "$github_ssh_dry_run"
grep -Fq 'ssh -T git@github.com' "$github_ssh_dry_run"
grep -Fq 'admin:public_key,admin:ssh_signing_key' \
  scripts/setup-github-ssh.sh
rm -rf "$github_ssh_test_home"
rm -f "$github_ssh_dry_run"

printf 'Checking isolated GitHub SSH interaction gates\n'
github_ssh_gate_home="$(mktemp -d)"
github_ssh_gate_bin="$(mktemp -d)"
github_ssh_gate_output="$(mktemp)"
github_ssh_gate_log="$(mktemp)"
mkdir -p "$github_ssh_gate_home/.ssh"
ssh-keygen -q \
  -t ed25519 \
  -N '' \
  -C '42442490+phoenix-error@users.noreply.github.com' \
  -f "$github_ssh_gate_home/.ssh/id_ed25519"

cat >"$github_ssh_gate_bin/gh" <<'EOF'
#!/usr/bin/env bash

if [[ "$1" == "auth" && "$2" == "status" ]]; then
  if [[ "${GH_TEST_AUTHENTICATED:-false}" != true ]]; then
    exit 1
  fi

  if [[ "${GH_TEST_SCOPES:-true}" == true ]]; then
    printf "Token scopes: 'admin:public_key', 'admin:ssh_signing_key'\n"
  fi
  exit 0
fi

if [[ "$1" == "api" && "$2" == "--paginate" ]]; then
  if [[ "${GH_TEST_API_FAILURE:-false}" == true ]]; then
    exit 1
  fi

  key_blob="$(awk 'NR == 1 { print $2 }' "$HOME/.ssh/id_ed25519.pub")"
  if [[ "$3" == "user/keys" ]]; then
    printf 'ssh-ed25519 %s isolated-test\n' "$key_blob"
  else
    printf '%s\n' "$key_blob"
  fi
  exit 0
fi

if [[ "$1" == "ssh-key" && "$2" == "add" ]]; then
  printf 'unexpected upload\n' >>"$GH_TEST_LOG"
  exit 0
fi

exit 1
EOF

cat >"$github_ssh_gate_bin/ssh-add" <<'EOF'
#!/usr/bin/env bash

if [[ "${1:-}" == "-l" ]]; then
  exit 1
fi

exit 0
EOF

cat >"$github_ssh_gate_bin/ssh" <<'EOF'
#!/usr/bin/env bash

printf "Hi isolated-test! You've successfully authenticated, but GitHub does not provide shell access.\n"
exit 1
EOF

chmod +x \
  "$github_ssh_gate_bin/gh" \
  "$github_ssh_gate_bin/ssh-add" \
  "$github_ssh_gate_bin/ssh"

set +e
GH_TEST_AUTHENTICATED=false \
  GH_TEST_LOG="$github_ssh_gate_log" \
  HOME="$github_ssh_gate_home" \
  PATH="$github_ssh_gate_bin:$PATH" \
  ./scripts/setup-github-ssh.sh </dev/null \
  >"$github_ssh_gate_output" 2>&1
github_ssh_gate_status=$?
set -e
[[ "$github_ssh_gate_status" -eq 2 ]]
grep -Fq 'Manual action required.' "$github_ssh_gate_output"
grep -Fq 'gh auth login' "$github_ssh_gate_output"

set +e
GH_TEST_AUTHENTICATED=true \
  GH_TEST_SCOPES=false \
  GH_TEST_LOG="$github_ssh_gate_log" \
  HOME="$github_ssh_gate_home" \
  PATH="$github_ssh_gate_bin:$PATH" \
  ./scripts/setup-github-ssh.sh </dev/null \
  >"$github_ssh_gate_output" 2>&1
github_ssh_gate_status=$?
set -e
[[ "$github_ssh_gate_status" -eq 2 ]]
grep -Fq 'Manual action required.' "$github_ssh_gate_output"
grep -Fq 'gh auth refresh' "$github_ssh_gate_output"

set +e
GH_TEST_API_FAILURE=true \
  GH_TEST_AUTHENTICATED=true \
  GH_TEST_LOG="$github_ssh_gate_log" \
  HOME="$github_ssh_gate_home" \
  PATH="$github_ssh_gate_bin:$PATH" \
  ./scripts/setup-github-ssh.sh </dev/null \
  >"$github_ssh_gate_output" 2>&1
github_ssh_gate_status=$?
set -e
[[ "$github_ssh_gate_status" -eq 1 ]]
grep -Fq 'Could not inspect GitHub authentication keys.' \
  "$github_ssh_gate_output"

for run_number in 1 2; do
  GH_TEST_AUTHENTICATED=true \
    GH_TEST_LOG="$github_ssh_gate_log" \
    HOME="$github_ssh_gate_home" \
    PATH="$github_ssh_gate_bin:$PATH" \
    ./scripts/setup-github-ssh.sh \
    >"$github_ssh_gate_output"
done

grep -Fq 'GitHub SSH authentication succeeded.' "$github_ssh_gate_output"
[[ ! -s "$github_ssh_gate_log" ]]
[[ "$(wc -l <"$github_ssh_gate_home/.ssh/allowed_signers" | tr -d ' ')" -eq 1 ]]

rm -rf "$github_ssh_gate_home"
rm -rf "$github_ssh_gate_bin"
rm -f "$github_ssh_gate_output"
rm -f "$github_ssh_gate_log"

printf 'Checking excluded tools and applications\n'
for forbidden in \
  '"npm:@higgsfield/cli"' \
  '"npm:firecrawl-cli"' \
  '"npm:@openai/codex"' \
  '"npm:@withgraphite/graphite-cli"' \
  '"npm:portless"' \
  '"npm:snapai"' \
  'brew "graphite"' \
  'brew "graphite-cli"' \
  'brew "linear"' \
  'brew "neovim"' \
  '"~/.config/nvim"' \
  'cask "affinity-designer"' \
  'cask "affinity-photo"' \
  'cask "affinity-publisher"' \
  'cask "arc"' \
  'cask "claude-code"' \
  'cask "codex"' \
  'cask "copilot-cli"' \
  'cask "figma"' \
  'cask "github"' \
  'cask "keepingyouawake"' \
  'cask "linear"' \
  'cask "linear-linear"' \
  'cask "obsidian"' \
  'cask "parsec"' \
  'cask "proton-pass"' \
  'cask "slack"' \
  'cask "spotlight"' \
  'cask "stats"' \
  'cask "stremio"' \
  'cask "textmate"' \
  'cask "tower"' \
  'cask "zulu@17"' \
  'cask "zed"' \
  'cask "xcode-beta"'; do
  if grep -Fq "$forbidden" mise.toml Brewfile Brewfile.mas; then
    printf 'Forbidden setup entry found: %s\n' "$forbidden" >&2
    exit 1
  fi
done

printf 'Checking managed application inventory\n'
for managed_cask in \
  'cask "chatgpt"' \
  'cask "claude"' \
  'cask "curseforge"' \
  'cask "expo-orbit"' \
  'cask "google-chrome"' \
  'cask "hoppscotch"' \
  'cask "iina"' \
  'cask "imageoptim"' \
  'cask "localsend"' \
  'cask "minecraft"' \
  'cask "multiviewer"' \
  'cask "openusage"' \
  'cask "readdle-spark"' \
  'cask "thebrowsercompany-dia"' \
  'cask "whatsapp"'; do
  grep -Fq "$managed_cask" Brewfile
done

grep -Fq 'brew "getsentry/tools/sentry", trusted: true' Brewfile
grep -Fq 'brew "fastlane"' Brewfile
grep -Fq '  fastlane' scripts/doctor.sh
grep -Fq 'brew "git-lfs"' Brewfile
grep -Fq '  git-lfs' scripts/doctor.sh
grep -Fq 'brew "mobile-dev-inc/tap/maestro", trusted: true' Brewfile
grep -Fq 'brew "tmux"' Brewfile
grep -Fq '  tmux' scripts/doctor.sh
grep -Fq 'brew "yt-dlp"' Brewfile
grep -Fq 'brew "infisical/get-cli/infisical", trusted: true' Brewfile
grep -Fq 'cask "pear-devs/pear/pear-desktop", trusted: true' Brewfile
grep -Fq 'cask "xykong/tap/flux-markdown", trusted: true' Brewfile
grep -Fq 'mas "Actions by Moleskine", id: 1227402276' Brewfile.mas
grep -Fq 'mas "Timepage", id: 989178902' Brewfile.mas

printf 'Checking editor ownership\n'
grep -Fq 'cask "cursor"' Brewfile
grep -Fq 'cask "visual-studio-code"' Brewfile
grep -Fq '"~/Library/Application Support/Code/User/settings.json" = { source = "home/.config/editors/vscode/settings.json" }' mise.toml
grep -Fq '"~/Library/Application Support/Cursor/User/settings.json" = { source = "home/.config/editors/cursor/settings.json" }' mise.toml

for editor in cursor vscode; do
  grep -Fq '"workbench.colorTheme": "Rosé Pine Moon"' \
    "home/.config/editors/${editor}/settings.json"
  grep -Fq '"editor.fontFamily": "Hack Nerd Font Mono"' \
    "home/.config/editors/${editor}/settings.json"
done

grep -Fq 'mvllow.rose-pine' home/.config/editors/extensions.txt

if grep -RFqi 'strigo.linear' home/.config/editors; then
  printf 'Linear must not be part of the managed editor setup.\n' >&2
  exit 1
fi

printf 'Checking Python and React editor setup\n'
for runtime in \
  'java = "zulu-17"' \
  'python = "3.12"' \
  'uv = "latest"' \
  'ruff = "latest"' \
  '"npm:@biomejs/biome" = "latest"' \
  '"npm:@posthog/cli" = "latest"' \
  '"npm:prettier" = "latest"'; do
  grep -Fq "$runtime" mise.toml
done

grep -Fq 'UV_PYTHON = { value = "{{ tools.python.path }}", tools = true }' mise.toml

if grep -Eq 'brew "(python(@3\.12)?|uv|ruff|biome|prettier)"' Brewfile; then
  printf 'Python and formatter tooling must be managed by mise, not Homebrew.\n' >&2
  exit 1
fi

if grep -Fq 'cask "zulu@17"' Brewfile; then
  printf 'Zulu JDK 17 must be managed by mise, not Homebrew.\n' >&2
  exit 1
fi

if grep -Eq '^vscode ' Brewfile; then
  printf 'Editor extensions must use the shared cross-editor installer.\n' >&2
  exit 1
fi

grep -Fq -- '--list-extensions' scripts/install-editor-extensions.sh
grep -Fq 'Already installed for %s: %s' scripts/install-editor-extensions.sh

for extension in \
  'biomejs.biome' \
  'bradlc.vscode-tailwindcss' \
  'charliermarsh.ruff' \
  'dbaeumer.vscode-eslint' \
  'esbenp.prettier-vscode' \
  'expo.vscode-expo-tools' \
  'yoavbls.pretty-ts-errors'; do
  grep -Fq "$extension" home/.config/editors/extensions.txt
done

for editor in cursor vscode; do
  if ! LC_ALL=C sort -c "home/.config/editors/${editor}/extensions.txt" ||
    [[ -n "$(sort \
      home/.config/editors/extensions.txt \
      "home/.config/editors/${editor}/extensions.txt" | uniq -d)" ]]; then
    printf '%s extension inventories must be sorted and non-overlapping.\n' "$editor" >&2
    exit 1
  fi
done

LC_ALL=C sort -c home/.config/editors/extensions.txt

for settings_file in \
  home/.config/editors/cursor/settings.json \
  home/.config/editors/vscode/settings.json; do
  grep -Fq '"editor.defaultFormatter": "charliermarsh.ruff"' "$settings_file"
  grep -Fq '"editor.defaultFormatter": "biomejs.biome"' "$settings_file"
  grep -Fq '"editor.defaultFormatter": "esbenp.prettier-vscode"' "$settings_file"
  grep -Fq '"source.fixAll.ruff": "explicit"' "$settings_file"
  grep -Fq '"source.organizeImports.ruff": "explicit"' "$settings_file"
  grep -Fq '"python-envs.alwaysUseUv": true' "$settings_file"
done

if grep -RFqi 'graphite' home/.config/editors; then
  printf 'Graphite must not be part of the managed editor setup.\n' >&2
  exit 1
fi

printf 'Checking Git and SSH ownership\n'
grep -Fq '"~/.gitconfig" = {}' mise.toml
grep -Fq '"~/.config/git/ignore" = {}' mise.toml
grep -Fq '"~/.ssh/config" = {}' mise.toml
grep -Fq 'name = phoenix-error' home/.gitconfig
grep -Fq 'email = 42442490+phoenix-error@users.noreply.github.com' home/.gitconfig
grep -Fq 'signingkey = ~/.ssh/id_ed25519.pub' home/.gitconfig
grep -Fq 'format = ssh' home/.gitconfig
grep -Fq 'gpgsign = true' home/.gitconfig
grep -Fq 'allowedSignersFile = ~/.ssh/allowed_signers' home/.gitconfig

if grep -Fq '.gitconfig.local' home/.gitconfig; then
  printf 'Managed Git configuration must not depend on a local include.\n' >&2
  exit 1
fi

if grep -Fq 'config.local' home/.ssh/config; then
  printf 'Managed SSH configuration must not depend on a local include.\n' >&2
  exit 1
fi

if grep -Fq '.zshrc.local' home/.zshrc; then
  printf 'Managed Zsh configuration must not depend on a local include.\n' >&2
  exit 1
fi

printf 'Checking Ghostty and Herdr ownership\n'
grep -Fq 'cask "ghostty"' Brewfile
grep -Fq 'brew "herdr"' Brewfile
grep -Fq '"~/.config/ghostty" = {}' mise.toml
grep -Fq '"~/.config/herdr/config.toml" = {}' mise.toml

for ghostty_setting in \
  'theme = Rose Pine Moon' \
  'font-family = Hack Nerd Font' \
  'background-opacity = 0.8' \
  'background-blur = 50'; do
  grep -Fq "$ghostty_setting" home/.config/ghostty/config.ghostty
done

ghostty_command=""
if command -v ghostty >/dev/null 2>&1; then
  ghostty_command="$(command -v ghostty)"
elif [[ -x /Applications/Ghostty.app/Contents/MacOS/ghostty ]]; then
  ghostty_command="/Applications/Ghostty.app/Contents/MacOS/ghostty"
fi

if [[ -n "$ghostty_command" ]]; then
  XDG_CONFIG_HOME="$REPO_ROOT/home/.config" \
    "$ghostty_command" +show-config >/dev/null
fi

if grep -Eq '^\[keys(\.|\])' home/.config/herdr/config.toml; then
  printf 'Herdr keybindings must use its defaults, not managed overrides.\n' >&2
  exit 1
fi

grep -Fq 'name = "rose-pine"' home/.config/herdr/config.toml
grep -Fq 'panel_bg = "reset"' home/.config/herdr/config.toml
grep -Fq 'surface_dim = "#232136"' home/.config/herdr/config.toml
grep -Fq 'blue = "#3e8fb0"' home/.config/herdr/config.toml
grep -Fq 'peach = "#ea9a97"' home/.config/herdr/config.toml

if command -v herdr >/dev/null 2>&1; then
  HERDR_CONFIG_PATH="$REPO_ROOT/home/.config/herdr/config.toml" \
    herdr config check >/dev/null
fi

printf 'Checking Zsh plugin ownership\n'
if grep -En 'brew "(zsh-autosuggestions|zsh-syntax-highlighting|zsh-history-substring-search|zsh-autopair|fzf-tab|forgit)"' Brewfile; then
  printf 'Zsh plugins must be managed by Antidote, not Homebrew.\n' >&2
  exit 1
fi

for required_plugin in \
  "Aloxaf/fzf-tab" \
  "hlissner/zsh-autopair" \
  "zsh-users/zsh-autosuggestions" \
  "zsh-users/zsh-history-substring-search" \
  "zsh-users/zsh-syntax-highlighting"; do
  if ! grep -Fq "$required_plugin" home/.zsh_plugins.txt; then
    printf 'Required Antidote plugin missing: %s\n' "$required_plugin" >&2
    exit 1
  fi
done

printf 'Checking editor ownership policy\n'
if [[ -e home/.config/nvim ]]; then
  printf 'Neovim is not part of this setup.\n' >&2
  exit 1
fi

grep -Fq 'export EDITOR="cursor --wait"' home/.zshrc

printf 'Checking single setup entry point\n'
if [[ -e apply.sh ]]; then
  printf 'bootstrap.sh must be the only setup entry point.\n' >&2
  exit 1
fi

grep -Fq 'mise bootstrap dotfiles apply' bootstrap.sh
grep -Fq '[tasks.setup]' mise.toml
grep -Fq 'lockfile_platforms = ["macos-arm64"]' mise.toml
grep -Fq 'minimum_release_age = "7d"' mise.toml
grep -Fq 'run = "./bootstrap.sh"' mise.toml
if grep -Fq '[tasks.bootstrap]' mise.toml; then
  printf 'The repository task must not collide with mise bootstrap.\n' >&2
  exit 1
fi

printf 'Checking global agent mappings\n'
for agent_target in \
  '"~/.agents.md" = { source = "home/AGENTS.md" }' \
  '"~/.claude/CLAUDE.md" = { source = "home/AGENTS.md" }'; do
  if ! grep -Fq "$agent_target" mise.toml; then
    printf 'Global agent mapping missing: %s\n' "$agent_target" >&2
    exit 1
  fi
done

if grep -Fq '"~/AGENTS.md"' mise.toml ||
  grep -Fq '"~/.agents/AGENTS.md"' mise.toml; then
  printf 'Legacy global agent mapping found.\n' >&2
  exit 1
fi

if grep -Eqi 'opencode|codex' mise.toml mise.lock Brewfile; then
  printf 'OpenCode and the standalone Codex CLI must not be part of the managed setup.\n' >&2
  exit 1
fi

if grep -Eqi 'codex|openai-codex|opencode' home/.claude/settings.json; then
  printf 'Codex and OpenCode must not be enabled through Claude plugins or marketplaces.\n' >&2
  exit 1
fi

grep -Fq '"teammateMode": "tmux"' home/.claude/settings.json

printf 'Checking Claude plugin and permission policy\n'
grep -Fq '"defaultMode": "auto"' home/.claude/settings.json
grep -Fq '"ENABLE_LSP_TOOL": "1"' home/.claude/settings.json
grep -Fq '"pyright-lsp@claude-plugins-official": true' home/.claude/settings.json
grep -Fq '"typescript-lsp@claude-plugins-official": true' home/.claude/settings.json

for removed_claude_entry in \
  'andrej-karpathy-skills' \
  'karpathy-skills' \
  'claude-md-management' \
  'commit-commands' \
  'hookify' \
  'ponytail' \
  'ralph-loop' \
  'understand-anything' \
  '"defaultMode": "bypassPermissions"' \
  '"skipDangerousModePermissionPrompt": true'; do
  if grep -Fq "$removed_claude_entry" home/.claude/settings.json; then
    printf 'Removed Claude setting is still present: %s\n' \
      "$removed_claude_entry" >&2
    exit 1
  fi
done

printf 'Checking Starship theme\n'
grep -Fq 'palette = "rose_pine_moon"' home/.config/starship.toml
grep -Fq '[palettes.rose_pine_moon]' home/.config/starship.toml
grep -Fq 'base = "#232136"' home/.config/starship.toml
grep -Fq 'iris = "#c4a7e7"' home/.config/starship.toml

printf 'Checking managed agent CLIs\n'
for agent_package in \
  '"npm:@anthropic-ai/claude-code"' \
  '"npm:@posthog/cli"'; do
  if ! grep -Fq "$agent_package" mise.toml; then
    printf 'Managed agent CLI missing: %s\n' "$agent_package" >&2
    exit 1
  fi
done

grep -Fq 'Use `posthog-cli` for deterministic PostHog queries' home/AGENTS.md
grep -Fq 'Use the `sentry` CLI for Sentry issues' home/AGENTS.md

printf 'Checking Homebrew trust ownership\n'
if [[ -e home/.homebrew/trust.json ]]; then
  printf 'Generated Homebrew trust state must not be tracked.\n' >&2
  exit 1
fi

git check-ignore --quiet home/.homebrew/trust.json
grep -Fq '"~/.homebrew/Brewfile" = { source = "Brewfile" }' mise.toml

if grep -REn 'HOMEBREW_NO_REQUIRE_TAP_TRUST' \
  --exclude-dir=.git \
  --exclude='test.sh' \
  .; then
  printf 'Homebrew tap trust must not be disabled.\n' >&2
  exit 1
fi

printf 'Checking mise bootstrap configuration\n'
if grep -Eq '^dotfiles\.root = "\{\{' mise.toml ||
  grep -E '^"com\.apple\.screencapture".*\{\{' mise.toml; then
  printf 'mise does not render templates in these bootstrap fields.\n' >&2
  exit 1
fi

grep -Fq 'defaults write com.apple.screencapture location' \
  scripts/configure-macos.sh
grep -Fq '"com.apple.HIToolbox" = { AppleFnUsageType = 0 }' mise.toml
grep -Fq 'Fn or Globe is free for Aqua Voice' scripts/doctor.sh
grep -Fq 'Infisical CLI is authenticated' scripts/doctor.sh
grep -Fq 'ANDROID_HOME points to the standard macOS Android SDK' scripts/doctor.sh
grep -Fq 'Android emulator and platform-tools directories are on PATH' \
  scripts/doctor.sh
grep -Fq 'managed agent skills are linked for Claude Code and Cursor' scripts/doctor.sh
grep -Fq 'mise bootstrap dotfiles status --missing' scripts/doctor.sh
grep -Fq 'mise bootstrap macos defaults status --missing' scripts/doctor.sh
grep -Fq 'Homebrew formulae and casks satisfy Brewfile' scripts/doctor.sh
grep -Fq 'No unmanaged Homebrew formulae, casks, or taps are installed' \
  scripts/doctor.sh
grep -Fq 'Claude Auto mode, Tmux teams, and LSP plugins are configured' \
  scripts/doctor.sh

printf 'Checking manual Android Studio ownership\n'
grep -Fq 'cask "android-studio"' Brewfile
grep -Fq 'java = "zulu-17"' mise.toml
grep -Fq 'ANDROID_HOME = "{{ env.HOME }}/Library/Android/sdk"' mise.toml
grep -Fq '"{{ env.HOME }}/Library/Android/sdk/emulator"' mise.toml
grep -Fq '"{{ env.HOME }}/Library/Android/sdk/platform-tools"' mise.toml
grep -Fq 'export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"' \
  home/.zshrc

if [[ -e scripts/configure-android.sh ]] ||
  [[ -e config/android/sdk-packages.txt ]] ||
  grep -Fq 'android-commandlinetools' Brewfile ||
  grep -Fq '[tasks.android]' mise.toml ||
  grep -Fq '[tasks."android:status"]' mise.toml; then
  printf 'Android SDK and emulator setup must remain manual in Android Studio.\n' >&2
  exit 1
fi

for forbidden_android_automation in \
  'React_Native_API_35' \
  'mise run android:status' \
  'Android-SDK-Lizenzen während des Bootstrap' \
  'Automatisches Android Setup'; do
  if grep -Fq "$forbidden_android_automation" README.md docs/setup-guide.html; then
    printf 'Automated Android setup reference found: %s\n' \
      "$forbidden_android_automation" >&2
    exit 1
  fi
done

printf 'Checking GitHub SSH automation\n'
grep -Fq 'scripts/setup-github-ssh.sh' bootstrap.sh
grep -Fq '[tasks."github:ssh"]' mise.toml
grep -Fq 'MANUAL_ACTION_EXIT=2' scripts/setup-github-ssh.sh
grep -Fq 'gh auth login' scripts/setup-github-ssh.sh
grep -Fq 'gh auth refresh' scripts/setup-github-ssh.sh
grep -Fq 'ssh -T git@github.com' scripts/setup-github-ssh.sh
grep -Fq 'GitHub SSH key is configured locally' scripts/doctor.sh
grep -Fq 'GitHub SSH key is registered for authentication and signing' \
  scripts/doctor.sh

printf 'Checking manual interaction gates\n'
grep -Fq 'MANUAL_ACTION_EXIT=2' bootstrap.sh
grep -Fq 'wait_for_manual_action' bootstrap.sh
grep -Fq 'scripts/install-mas-apps.sh' bootstrap.sh
grep -Fq 'scripts/install-mas-apps.sh' mise.toml
grep -Fq 'MANUAL_ACTION_EXIT=2' scripts/install-mas-apps.sh
grep -Fq 'Manual interaction gates' README.md
grep -Fq 'Exit code 2' README.md
if grep -Fq 'Warning: One or more Mac App Store applications' bootstrap.sh; then
  printf 'Mac App Store failures must block bootstrap completion.\n' >&2
  exit 1
fi

printf 'Checking global agent skill profile\n'
grep -Fq 'bunx' scripts/install-agent-skills.sh
grep -Fq -- '--bun' scripts/install-agent-skills.sh
grep -Fq '"skills@${SKILLS_CLI_VERSION}"' scripts/install-agent-skills.sh
grep -Fq 'readonly TARGET_AGENTS=("claude-code" "cursor")' \
  scripts/install-agent-skills.sh
grep -Eq '/tree/[0-9a-f]{40}([/|])' \
  home/.config/skills/default-skills.txt
grep -Fq 'scripts/install-agent-skills.sh' bootstrap.sh
grep -Fq '[tasks."agents:skills"]' mise.toml

for excluded_skill_source in \
  'karpathy' \
  'opencode' \
  'ponytail' \
  'understand-anything'; do
  if grep -Fqi "$excluded_skill_source" \
    home/.config/skills/default-skills.txt; then
    printf 'Excluded agent skill source found: %s\n' \
      "$excluded_skill_source" >&2
    exit 1
  fi
done

mise_command="${MISE_BIN:-}"
if [[ -z "$mise_command" ]] && command -v mise >/dev/null 2>&1; then
  mise_command="$(command -v mise)"
fi

if [[ -n "$mise_command" ]]; then
  CI=1 "$mise_command" tasks ls >/dev/null

  validation_home="$(mktemp -d)"
  validation_status="$(mktemp)"
  trap 'rm -rf "$validation_home"; rm -f "$validation_status"' EXIT
  mkdir -p "$validation_home/github/phoenix-error"
  ln -s "$REPO_ROOT" "$validation_home/github/phoenix-error/dotfiles"

  HOME="$validation_home" CI=1 "$mise_command" \
    bootstrap dotfiles status >"$validation_status"

  if grep -Fq 'source missing' "$validation_status"; then
    printf 'mise reports a missing dotfile source.\n' >&2
    cat "$validation_status" >&2
    exit 1
  fi
else
  printf 'SKIP  mise executable is unavailable\n'
fi

printf 'Checking Raycast signing identity\n'
grep -Fq 'EXPECTED_TEAM_ID="SY64MV22J9"' scripts/install-raycast-beta.sh

printf 'Checking declarative Homebrew cleanup\n'
grep -Fq 'run brew bundle cleanup \' bootstrap.sh
grep -Fq -- '--force \' bootstrap.sh
grep -Fq -- '--formula \' bootstrap.sh
grep -Fq -- '--cask \' bootstrap.sh
grep -Fq -- '--tap \' bootstrap.sh
if grep -Fq -- '--zap' bootstrap.sh ||
  grep -REn 'brew uninstall|mise prune' \
  --exclude-dir=.git \
  --exclude='*.md' \
  --exclude='test.sh' \
  .; then
  printf 'Unsupported destructive package-manager operation found.\n' >&2
  exit 1
fi

printf 'Checking common secret patterns\n'
if grep -REn \
  -e '-----BEGIN ([A-Z ]+ )?PRIVATE KEY-----|AKIA[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9_]{20,}|sk-[A-Za-z0-9]{20,}' \
  --exclude-dir=.git \
  --exclude='test.sh' \
  .; then
  printf 'Possible committed secret found.\n' >&2
  exit 1
fi

printf 'Checking typography policy\n'
if grep -RFn \
  -e $'\u2014' \
  --exclude-dir=.git \
  --exclude='test.sh' \
  .; then
  printf 'Em dash found. Use a plain hyphen instead.\n' >&2
  exit 1
fi

printf 'Checking repository whitespace\n'
git diff --check

printf 'All repository tests passed.\n'
