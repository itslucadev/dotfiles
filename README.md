# macOS Dotfiles

This public repository configures Luca's personal Apple Silicon Mac for terminal work, AI agents, and React Native development.

mise is the central orchestrator.

Homebrew installs formulae, desktop applications, and fonts.

mise installs Node.js, Bun, Python, Java, native developer tools, and global npm-backed CLIs, with Bun acting as the npm package manager.

The lockfile targets Apple Silicon macOS only, and fuzzy versions must be at least seven days old before mise selects them.

This limits exposure to brand-new supply-chain releases while the committed lockfile keeps accepted versions reproducible.

## Status

The repository is prepared on the current Mac without running the setup there.

No real setup command has been run on the current Mac while preparing this repository.

The recommended first complete acceptance test is a disposable macOS VM or a spare Mac.

The current Mac can also be used for a final rehearsal immediately before it is erased, after a verified backup exists.

## Quick Start on a New Mac

Sign in to the Mac with an administrator account and complete the initial macOS onboarding.

Install the Xcode Command Line Tools:

```sh
xcode-select --install
```

Create the expected parent directory and clone the repository:

```sh
mkdir -p ~/github/phoenix-error
git clone https://github.com/phoenix-error/dotfiles.git ~/github/phoenix-error/dotfiles
cd ~/github/phoenix-error/dotfiles
```

Run the bootstrap:

```sh
./bootstrap.sh
```

The fixed clone path allows the repository `mise.toml` to serve as the global mise configuration while keeping dotfile sources predictable.

The setup is idempotent and can be rerun after resolving a manual prerequisite.

After the command finishes, open the offline [interactive setup guide](docs/setup-guide.html) to complete permissions, remaining application logins, and application onboarding.

## What the Bootstrap Does

The bootstrap:

- Verifies Apple Silicon macOS.
- Ensures the Xcode Command Line Tools are available.
- Installs Homebrew when necessary.
- Applies `Brewfile`.
- Removes Homebrew formulae, casks, and taps that are not required by `Brewfile`.
- Installs GitHub CLI and the remaining native command-line tools.
- Installs locked mise runtimes and global CLIs.
- Installs the commit-pinned global skills for Claude Code and Cursor through BunX.
- Applies the managed Zsh, Starship, WezTerm, Ghostty, Herdr, Git, SSH, editor, Claude, and global agent dotfiles.
- Installs the Herdr agent integrations for Claude Code, Cursor, and Pi.
- Creates or reuses one Ed25519 key for GitHub authentication and commit signing, loads it through the macOS Keychain, and maintains the local allowed signers file.
- Installs the saved VS Code and Cursor extensions through their native command-line interfaces.
- Links the repository `Brewfile` to Homebrew's global `~/.homebrew/Brewfile`.
- Creates `~/Developer` as the shared project directory.
- Applies the confirmed macOS defaults.
- Reserves shortcuts for Raycast and CleanShot.
- Installs the signed Raycast v2 Beta beside Raycast v1.
- Installs the managed Mac App Store applications after any required App Store interaction is complete.
- Runs the setup doctor.

The Homebrew reconciliation uses regular cask uninstall behavior and never passes `--zap`, so application data and shared support files are preserved.

It does not remove manually installed applications outside Homebrew or write directly to the macOS privacy database.

## Manual interaction gates

The bootstrap treats every manual prerequisite for a later automated stage as a gate.

In an interactive terminal, it pauses at the gate, explains the required action, waits for completion, verifies the result, and only then continues.

In a non-interactive environment, it stops with Exit code 2 and prints the command that must be rerun after the action is complete.

The gated interactions are:

- Finishing the Xcode Command Line Tools installer.
- Choosing the passphrase for a newly generated SSH key.
- Completing GitHub CLI browser login and approving the key-management scopes.
- Comparing and accepting GitHub's SSH host fingerprint on the first connection.
- Signing in to the Mac App Store and claiming applications that the Apple Account has never downloaded.
- Entering the administrator password when a signed application must be installed into `/Applications`.

The final success message is printed only after all of these gates and their dependent automated stages have completed.

Privacy permissions, application-specific logins, Xcode onboarding, Android Studio onboarding, and smoke tests have no dependent bootstrap stage.
They remain explicitly documented in the offline guide and are reported by `mise run doctor` where they can be detected.

## Declarative Ownership

The repository keeps configuration in the native declarative format of the tool that owns it:

- `Brewfile` owns the exact desired top-level Homebrew formulae, casks, taps, fonts, and Homebrew 6 trust declarations.
- `Brewfile.mas` owns Mac App Store applications.
- `mise.toml` owns runtimes, Bun-backed global CLIs, dotfile symlinks, tasks, and scalar macOS defaults.
- `mise.lock` contains the resolved mise tool versions and is generated only by mise.
- `home/` contains public configuration that mise symlinks into the home directory.
- `home/.zsh_plugins.txt` is the only source of Zsh plugins.

`bootstrap.sh` is the only setup entry point.

It installs the first dependencies needed before mise is available, then runs the remaining stages in the required order, because Homebrew must install mise before mise can orchestrate the rest.

It calls seven helper scripts that can change the Mac or connected accounts:

- `scripts/configure-macos.sh` owns the dynamic screenshot path and nested `AppleSymbolicHotKeys` dictionary that mise macOS defaults cannot represent correctly.
- `scripts/install-agent-skills.sh` reconciles the pinned global skill profile for Claude Code and Cursor through BunX, then installs the NotebookLM skill through its own CLI.
- `scripts/install-editor-extensions.sh` installs the declarative extension inventories through the native VS Code and Cursor CLIs.
- `scripts/install-herdr-integrations.sh` asks Herdr to install its own agent hooks.
- `scripts/install-mas-apps.sh` installs the declared Mac App Store applications and gates account interaction.
- `scripts/install-raycast-beta.sh` installs and verifies Raycast Beta because it has no official Homebrew cask.
- `scripts/setup-github-ssh.sh` configures the local SSH identity and registers its public key with GitHub for authentication and signing.

The read-only `scripts/doctor.sh` inspects the result without configuring the Mac.

This repository has no test suite. Configuration is verified with `./bootstrap.sh --dry-run` and the setup doctor.

All scalar macOS settings with static values use mise's friendly or raw defaults sections.

mise 2026.7.17 does not render templates inside raw macOS default values, so the user-specific screenshot path cannot live there without becoming a literal `{{ env.HOME }}` string.

## Reapply Changes

After pulling repository changes, run the same command as on a new Mac:

```sh
./bootstrap.sh
```

Every stage is idempotent, so desired packages, applied dotfiles, and applied macOS defaults are left alone.

Homebrew formulae, casks, and taps that are neither declared nor required as dependencies are removed.

The equivalent repository task is:

```sh
mise run setup
```

The task is deliberately named `setup`.

mise reserves the `bootstrap` name for its built-in bootstrap pipeline and automatically runs a task with that name afterward, so using the same name here would repeat the repository setup.

Inspect the setup without changing the Mac:

```sh
./bootstrap.sh --dry-run
```

## Managed Applications

Homebrew installs:

- AltTab
- Android Studio
- Aqua Voice
- Caffeine
- ChatGPT
- Claude Desktop
- CleanMyMac
- CleanShot
- CurseForge
- Cursor
- Dia
- Expo Orbit
- FluxMarkdown
- Ghostty
- Google Chrome
- Hack Nerd Font
- Hoppscotch
- IINA
- ImageOptim
- LocalSend
- Minecraft
- MultiViewer
- OpenUsage
- Pear Desktop for YouTube Music
- Proton VPN
- Raycast v1
- Spark
- Tailscale
- Visual Studio Code
- WezTerm
- WhatsApp

Homebrew also installs Fastlane, Git LFS, the Infisical CLI, the Maestro CLI, the Sentry CLI, Tmux, and YouTube-DLP.

The Mac App Store installs Actions, Apple Developer, Folder Quick Look, Helm, Notability, Obsidian Web Clipper, RocketSim, TestFlight, Timepage, and stable Xcode.

Magnet and Mela are installed on the current Mac but are deliberately not reinstalled. Raycast Window Management replaces Magnet.

Raycast v2 Beta comes from Raycast's official signed disk image because no official Homebrew cask exists.

The bootstrap installs Rosetta 2 when necessary because the current Minecraft launcher is still built for Intel Macs.

GatherOS, Maestro Studio, Recordly, and SimCam are direct-download applications covered by the manual setup checklist.

Affinity Designer, Affinity Photo, Affinity Publisher, Arc, Figma, GitHub Desktop, KeepingYouAwake, Linear, Magnet, Obsidian, Parsec, Proton Pass, Sentry Spotlight, Slack, Stats, Stremio, TextMate, Tower, and Xcode Beta are intentionally excluded.

## Managed Runtimes and Global CLIs

mise manages:

- Node.js LTS
- Bun
- Python 3.12
- uv
- Ruff
- Zulu JDK 17
- Agent Device
- AgentMail CLI
- Argent
- Biome
- Chrome DevTools axi
- Claude Code
- Context7 CLI
- EAS CLI
- gh-axi
- Lavish CLI
- Native SDK CLI
- NotebookLM CLI
- OpenSrc
- Pi Coding Agent
- Playwright CLI
- PostHog CLI
- Prettier
- Pyright
- QMD
- React Doctor
- Turbo
- TypeScript
- TypeScript Language Server
- Vercel CLI

The NotebookLM CLI is the one Python-backed entry. It is installed from PyPI as `notebooklm-mcp-cli` and provides the `nlm` command plus the NotebookLM skill.

All npm-backed CLIs, including Biome and Prettier, are installed by Bun through mise.

mise's seven-day minimum release age also applies to supported npm package resolution, including transitive npm dependencies.

Python, uv, and Ruff are installed directly by mise.

The global `UV_PYTHON` setting points uv at the Python interpreter selected by the active mise configuration, so a project-level mise version can still override the global Python 3.12 default.

Codex CLI, Portless, Higgsfield CLI, SnapAI, and Firecrawl CLI are intentionally excluded.

YouTube-DLP and the new Sentry CLI are installed through Homebrew because they are native command-line tools rather than project runtimes.

YouTube-DLP has no managed configuration in this repository.

Global `npm` and `undici` are not installed as separate tools.

Fastlane is installed through Homebrew for iOS and Android release automation.

XcodeGen is intentionally not installed because React Native does not require it and no managed project currently uses an XcodeGen `project.yml` specification.

## Shell and Terminal

The interactive stack is:

- Zsh as the shell.
- Antidote as the Zsh plugin manager.
- Starship as the prompt renderer.
- WezTerm as the primary terminal.
- Ghostty as an additional terminal.
- Herdr as the terminal agent multiplexer.

Oh My Zsh and Oh My Posh are not installed.

Antidote loads:

- Zsh Completions
- ez-compinit
- FZF Tab
- Zsh Autopair
- Zsh Autosuggestions
- Zsh You Should Use
- Zsh Bat
- Zsh Syntax Highlighting
- Zsh History Substring Search

The shell also configures FZF, Eza, Zoxide, Bat, Android SDK paths, and mise activation.

Starship uses the official Rose Pine Moon palette so the prompt matches WezTerm, Ghostty, Herdr, VS Code, and Cursor.

The `dev` alias opens `~/Developer`.

The bootstrap creates `~/Developer/appzudio` as the shared parent directory for all AppZudio projects.

The `appzudio` alias opens that parent directory.

Zsh plugins are managed only by Antidote through `home/.zsh_plugins.txt`.

Repository agent instructions explicitly prohibit installing individual Zsh plugins through Homebrew, Oh My Zsh, or manual clones.

WezTerm starts from Kun Chen's Rose Pine Moon styling with Hack Nerd Font, transparency, blur, minimal tabs, and resize-only window decorations.

Ghostty uses the same Rose Pine Moon theme, Hack Nerd Font, 15-point font size, 0.8 background opacity, and blur level 50.

Herdr starts from its built-in Rose Pine theme and overrides the supported color tokens with the official Rose Pine Moon palette.

Its panel background is reset so it inherits opacity and blur from the host terminal.

The repository manages only Herdr's onboarding, agent-panel, notification, and theme settings.

## VS Code and Cursor

Cursor is the primary editor.

`EDITOR` and `VISUAL` point at `cursor --wait`, so Git and other command-line tools open Cursor and wait for the file to close.

Neovim is intentionally not part of this setup.

Homebrew installs both Visual Studio Code and Cursor.

mise symlinks separate global `settings.json` files into the native macOS user settings location for each editor.

Both editors use Hack Nerd Font Mono, Rosé Pine Moon, automatic import updates, and the shared editor preferences already present on the current Mac.

Cursor keeps its Cursor-specific composer and terminal preferences in its own settings file.

The shared Python setup includes the Microsoft Python and debugger extensions, Python Environments, Ruff, uv-backed environment management, and the editor-specific Pyright or Pylance language server.

Ruff formats Python, applies safe fixes, and organizes imports on save.

Project-level `pyproject.toml` or `ruff.toml` settings take priority over the global editor defaults.

The shared React and React Native setup includes Biome, Prettier, ESLint, Tailwind CSS IntelliSense, Pretty TypeScript Errors, and the official Expo Tools extension.

Biome formats JavaScript, JSX, TypeScript, TSX, JSON, and JSONC on save.

Prettier formats CSS, SCSS, HTML, GraphQL, Markdown, and YAML on save.

Each project should still declare its own Biome, Prettier, and ESLint dependencies and configuration so the repository controls exact tool versions and rules.

Common extensions have one shared inventory.

VS Code and Cursor each have a second inventory for editor-specific extensions.

`scripts/install-editor-extensions.sh` is the single adapter that reads those declarative inventories and invokes each editor's native `--install-extension` command.

mise has no native VS Code extension backend.

Homebrew Bundle supports `vscode` entries, but it uses only the first supported editor CLI found on `PATH`.

With both applications installed, it would configure VS Code through `code` and leave Cursor unsynchronized.

The repository therefore keeps one shared manifest plus editor-specific additions and lets the mise task drive both native CLIs explicitly.

The installer reads each editor's installed extension list once and installs only missing entries.

Run the extension installer through mise after changing either inventory:

```sh
mise run editors:extensions
```

The inventories start from the current Mac and add the confirmed shared Python, React, and React Native tooling.

The Graphite extension was deliberately removed.

Zed is not installed or configured.

## Agent Configuration

One public `home/AGENTS.md` file is symlinked to:

- `~/.agents.md`
- `~/.claude/CLAUDE.md`

This gives the supported agents the same global working rules without maintaining duplicate files.

`~/.claude/CLAUDE.md` is a symlink to the same repository source as the global `~/.agents.md`.

The global instructions also name the command-line wrappers that agents must prefer over their built-in tools: `gh-axi` instead of `gh`, `lavish-axi` for visual review surfaces, `chrome-devtools-axi` for driving Chrome, `ctx7` for library documentation, and `nlm` for NotebookLM.

Every one of those tools is installed by this setup, and `home/.claude/settings.json` starts `gh-axi`, `chrome-devtools-axi`, and `lavish-axi` as session-start hooks.

`home/.claude/rules/context7.md` is the only managed Claude rule. It tells agents to use the mise-installed `ctx7` CLI rather than `npx ctx7@latest`, so documentation lookups also respect the pinned version and the minimum release age.

Herdr installs its own agent hooks through `mise run agents:herdr`. This repository never copies a generated hook file, and `~/.claude/hooks` is not a managed dotfile path.

OpenCode is not part of the setup.

Claude Code also receives the public `settings.json` and Bun-powered status line from this repository.

Claude Code is installed as a Bun-backed npm tool through mise.

Claude agent teams use Tmux split panes.

Herdr remains the primary multiplexer for persistent agent sessions.

Tmux is installed as a dedicated dependency for Claude's split-pane team display and does not currently have a managed configuration file.

Claude Code starts in Auto mode, which runs tasks without routine permission prompts while retaining Claude's background safety checks.

Auto mode availability depends on the active Claude plan, model, provider, and organization settings.

The Pyright and TypeScript LSP plugins remain enabled so Claude receives diagnostics, type information, definitions, and references while editing supported projects.

Claude authentication, caches, conversation history, local settings, and generated plugin state are not tracked.

The [ChatGPT desktop application](https://learn.chatgpt.com/docs/app) includes the Codex desktop experience.

The standalone Codex CLI and its configuration are not part of this setup.

The Claude Codex plugin and its marketplace are also excluded.

The global agent instructions tell agents to use PostHog CLI for deterministic PostHog work without storing its credentials in the repository.

## Global Agent Skills

The global skill profile is declared in `home/.config/skills/default-skills.txt`.

Every source is pinned to a full Git commit so a new Mac receives reviewed skill contents instead of whatever happens to be on a moving default branch.

The installer uses `bunx --bun skills@1.5.21`, never `npx`, and links the selected skills through the central `~/.agents/skills` store for Claude Code and Cursor.

The profile is deliberately small. It contains Matt Pocock's engineering, productivity, and misc skills, and nothing else.

His `skills/personal` folder is excluded because `obsidian-vault` points at a Windows vault path and `edit-article` encodes someone else's publishing workflow. His `deprecated` and `in-progress` folders are excluded as well.

`setup-matt-pocock-skills` is excluded because this repository installs those skills declaratively instead.

The NotebookLM skill is the one exception to the pinning rule. It ships inside the NotebookLM CLI package, so the installer runs `nlm skill install claude-code` and `nlm skill install cursor` after reconciling the inventory.

Vercel, Anthropic, Sentry, Expo, Argent, React Doctor, and animation skill sources were removed from the profile. Ponytail, Understand Anything, Karpathy skills, Codex skills, and OpenCode skills remain excluded.

Reconcile the profile after changing the inventory:

```sh
mise run agents:skills
```

To update a source, review the upstream `SKILL.md` changes, replace its full commit SHA in the inventory, and run the installer.

The repository does not copy local plugin caches or private skill folders.

## Git and SSH

The public `~/.gitconfig` manages the GitHub Noreply identity, the standard SSH signing key path, SSH commit signing, and the default branch.

The public SSH config loads the same `~/.ssh/id_ed25519` key through the macOS Keychain for GitHub authentication.

Using the public GitHub Noreply address keeps the personal email address private without requiring a separate local Git configuration.

`scripts/setup-github-ssh.sh` follows GitHub's documented macOS flow and owns the local key setup.

It creates the Ed25519 key only when neither key file exists, asks interactively for a new passphrase, and prompts to unlock an existing encrypted key when required.
It sets restrictive permissions, loads the key into the native SSH agent and macOS Keychain, and maintains `~/.ssh/allowed_signers`.

The helper pauses for GitHub CLI browser authentication when needed and requests only the scopes required to manage authentication and signing keys.

It registers the same public key as both an Authentication Key and a Signing Key.

It checks GitHub before each upload, so rerunning `mise run github:ssh` does not create duplicate registrations.

The helper also runs `ssh -T git@github.com`.
On the first connection it waits while the user compares GitHub's published host fingerprint and accepts it.
The bootstrap does not continue until local setup, both GitHub registrations, and SSH authentication have been verified.

This implements the official [Connecting to GitHub with SSH](https://docs.github.com/en/authentication/connecting-to-github-with-ssh) workflow.

SSH private keys, `known_hosts`, `authorized_keys`, `allowed_signers`, and authentication state are never copied into this repository.

## Secrets with Infisical

Infisical manages project and environment secrets without placing plaintext values in the public dotfiles repository.

The CLI stores its interactive login session in the system keyring and injects selected secrets only into the child process:

```sh
infisical login
infisical run -- bun run dev
```

Run `infisical init` inside an individual project when that project should be connected to an Infisical project.

The generated project reference can live in that project's repository when its visibility is appropriate, but it does not belong in these global dotfiles.

Do not source exported secrets globally from `.zshrc`, write them into this repository, or use Infisical as storage for SSH private keys.

GitHub CLI, Claude, EAS, Sentry, and similar tools keep using their own authentication stores.

## Manual Setup Checklist

### Apple Account and Mac App Store

- [ ] Sign in to the Mac App Store.
- [ ] Claim each managed App Store application once if the Apple Account has never downloaded it.
- [ ] Run `mise run apps:mas`.

### Xcode

- [ ] Launch `/Applications/Xcode.app` once and allow it to install additional components.
- [ ] Accept the Xcode license with `sudo xcodebuild -license accept`.
- [ ] Select stable Xcode with `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`.
- [ ] Install the required iOS simulator runtime in Xcode Settings under Platforms or Components.
- [ ] Keep Xcode Beta out of the active developer path.

### Android Studio

- [ ] Launch Android Studio and complete its setup wizard.
- [ ] Let Android Studio install the Android SDK, Android SDK Platform, and Android Virtual Device components.
- [ ] Follow the current [React Native Android environment guide](https://reactnative.dev/docs/set-up-your-environment?platform=android) in Android Studio.
- [ ] Confirm that Android Studio uses `~/Library/Android/sdk`.
- [ ] Create and start the required Android Virtual Device through Android Studio.
- [ ] Enable Developer options and USB debugging on any physical Android test device.

The shell configuration exposes `ANDROID_HOME`, `emulator`, and `platform-tools`.

mise exposes `JAVA_HOME` for Zulu JDK 17 when its shell activation is active.

The repository does not install Android SDK packages, accept Android licenses, or create an emulator.

Android Studio owns that state and provides the SDK Manager and Device Manager used by the official React Native instructions.

[React Native currently recommends Zulu JDK 17](https://reactnative.dev/docs/set-up-your-environment?platform=android).

[mise installs that JDK and automatically points `JAVA_HOME` at the active Java installation](https://mise.jdx.dev/lang/java.html), so the separate Homebrew `zulu@17` cask is intentionally unnecessary.

### Direct-download Applications

- [ ] Download [GatherOS](https://www.gatheros.co/) and move it to `/Applications`.
- [ ] Download [Maestro Studio](https://docs.maestro.dev/get-started/quickstart) for macOS and move it to `/Applications`.
- [ ] Download [Recordly](https://recordly.dev/) for macOS and move it to `/Applications`.
- [ ] Download [SimCam](https://simcam.swmansion.com/) and move it to `/Applications`.
- [ ] Grant GatherOS the capture permissions requested by the features that are used.
- [ ] Select a workspace in Maestro Studio and verify that it can see an iOS Simulator and Android emulator.
- [ ] Grant Recordly Screen Recording, Microphone, Camera, and System Audio permissions as needed.
- [ ] Complete the SimCam trial or license activation and approve its camera components when prompted.

These applications have no suitable Homebrew cask or Mac App Store entry in the managed setup.

### Additional Application Onboarding

- [ ] Sign in to Dia and choose whether browser data should sync.
- [ ] Link WhatsApp to the existing account.
- [ ] Sign in to Spark and add the required mail accounts.
- [ ] Sign in to CurseForge if account-backed mod synchronization is needed.
- [ ] Grant LocalSend Local Network access.
- [ ] Launch OpenUsage and review which local developer tools it may inspect.
- [ ] Verify that FluxMarkdown provides Finder Quick Look previews for Markdown files.

### Git and GitHub

- [ ] Confirm that bootstrap created `~/.ssh/id_ed25519` and prompted for a secure passphrase.
- [ ] Confirm that bootstrap paused for GitHub CLI browser login when authentication was missing.
- [ ] Confirm that bootstrap registered `~/.ssh/id_ed25519.pub` as both an Authentication Key and a Signing Key.
- [ ] Confirm the complete local and GitHub state with `./scripts/setup-github-ssh.sh --status`.
- [ ] Confirm that the first connection fingerprint was compared with GitHub's published fingerprint and `ssh -T git@github.com` succeeds.
- [ ] Push a signed commit and confirm that GitHub displays it as verified.

Never commit an alternate Git identity file, SSH private key, private SSH host inventory, or GitHub CLI authentication files.

### VS Code and Cursor

- [ ] Launch VS Code and confirm that Rosé Pine Moon and Hack Nerd Font Mono load.
- [ ] Launch Cursor and sign in.
- [ ] Confirm that Rosé Pine Moon and Hack Nerd Font Mono load in Cursor.
- [ ] Open a Python project and confirm that its `.venv` is discovered and Ruff formats on save.
- [ ] Open a React Native project and confirm that Biome, Prettier, ESLint, Tailwind, and Expo Tools activate only where their project configuration applies.
- [ ] Review extension publisher trust prompts in both editors.
- [ ] Run `mise run editors:extensions` again if an extension was temporarily unavailable during bootstrap.

### Raycast

- [ ] Launch Raycast v1 and complete its onboarding.
- [ ] Launch Raycast v2 Beta.
- [ ] Run `Migrate from Raycast v1` inside Raycast Beta.
- [ ] Confirm that migrated shortcuts are disabled in v1 to avoid conflicts.
- [ ] Set Raycast Beta as the login launcher.
- [ ] Set Command-Space as the primary Raycast shortcut.
- [ ] Grant Accessibility access when requested.
- [ ] Configure Raycast Window Management shortcuts.

The setup disables the native Command-Space Spotlight shortcut.

Raycast settings exports are not committed because they may contain clipboard history, AI conversations, authenticated extension data, and MCP configuration.

### AltTab

- [ ] Set Command-Tab as the AltTab shortcut.
- [ ] Grant Accessibility access.
- [ ] Grant Screen Recording access when requested.

### CleanShot

- [ ] Grant Screen Recording access.
- [ ] Grant Microphone access for recordings.
- [ ] Grant Accessibility access when requested.
- [ ] Set Command-Shift-3 to full-screen capture.
- [ ] Set Command-Shift-4 to area capture.
- [ ] Set Command-Shift-5 to all-in-one capture and recording.
- [ ] Set Command-Shift-6 to text capture.

The setup disables the corresponding native screenshot shortcuts.

### Aqua Voice

- [ ] Sign in to Aqua Voice.
- [ ] Grant Microphone access.
- [ ] Grant Accessibility access when requested.
- [ ] Set the Fn or Globe key as push-to-talk.

The setup configures macOS so pressing Fn or Globe has no native action, leaving the key available to Aqua Voice.

### CleanMyMac

- [ ] Activate the existing CleanMyMac license.
- [ ] Grant Full Disk Access when requested.
- [ ] Review background-item and notification prompts.

### Tailscale and Proton VPN

- [ ] Sign in to Tailscale.
- [ ] Approve the Tailscale network or system extension.
- [ ] Sign in to Proton VPN.
- [ ] Approve the Proton VPN configuration.

### RocketSim

- [ ] Launch RocketSim after Xcode and at least one Simulator runtime are installed.
- [ ] Grant Screen Recording or Accessibility access only when RocketSim requests it for a used feature.

### Agent and Developer Logins

- [ ] Authenticate Infisical with `infisical login`.
- [ ] Confirm the stored session with `infisical login status`.
- [ ] Launch ChatGPT, sign in, and select Codex when doing local software development.
- [ ] Launch Claude Desktop and sign in.
- [ ] Run Claude Code and complete its login.
- [ ] Confirm that Claude Auto mode is available for the active plan and model.
- [ ] Confirm that the Pyright and TypeScript LSP plugins are active.
- [ ] Authenticate PostHog CLI with `posthog-cli login`.
- [ ] Authenticate Sentry CLI with `sentry auth login`.
- [ ] Authenticate EAS with `eas login`.
- [ ] Authenticate Vercel with `vercel login`.
- [ ] Authenticate AgentMail if it is used.
- [ ] Complete any NotebookLM CLI browser login.
- [ ] Configure other agent tools without committing their credentials or histories.

### Ghostty and Herdr

- [ ] Launch Ghostty once and verify that Rose Pine Moon and Hack Nerd Font load.
- [ ] Grant Ghostty Accessibility access only if global terminal shortcuts are added later.
- [ ] Launch Herdr and verify its Rose Pine theme and system notification delivery.
- [ ] Keep Herdr's built-in keyboard shortcuts unless this repository explicitly changes that policy.

### Final Verification

- [ ] Open new WezTerm and Ghostty windows so the managed shell configuration is active.
- [ ] Verify the managed extension inventories in VS Code and Cursor.
- [ ] Run `mise doctor`.
- [ ] Run `mise run doctor`.
- [ ] Build and launch one React Native project on an iOS Simulator.
- [ ] Build and launch one React Native project on the Android emulator.
- [ ] Reboot once and verify login items, shortcuts, VPNs, and permissions.

## Safe Test Strategy

The repository can be tested on the current Mac later, but that is not equivalent to a clean-machine test because Homebrew packages, applications, Keychain entries, permissions, and caches already exist.

Use this order:

1. Run `./bootstrap.sh --dry-run` while preparing the repository.
2. Use a disposable macOS virtual machine for a clean bootstrap when possible.
3. Use a separate macOS user only for per-user dotfiles and defaults, remembering that `/Applications` and Homebrew remain shared.
4. If desired, run the real bootstrap on the current user only immediately before the planned erase and only after verifying a Time Machine or equivalent backup.
5. Perform the final acceptance test on the new Mac before erasing the old one.

The bootstrap uninstalls unmanaged Homebrew formulae and casks, untaps unmanaged taps, installs managed applications, links dotfiles, applies macOS defaults, and reserves keyboard shortcuts.

It preserves recursive formula dependencies, formula dependencies required by managed casks, Mac App Store applications, editor extensions, and application data belonging to removed casks.

For that reason, the dry-run and virtual-machine stages should happen before any live rehearsal on the current user.

## Keyboard Shortcuts

The intended ownership is:

| Shortcut | Owner | Action |
| --- | --- | --- |
| Command-Space | Raycast Beta | Open Raycast |
| Command-Tab | AltTab | Switch applications |
| Fn or Globe | Aqua Voice | Push-to-talk |
| Command-Shift-3 | CleanShot | Full-screen capture |
| Command-Shift-4 | CleanShot | Area capture |
| Command-Shift-5 | CleanShot | All-in-one capture and recording |
| Command-Shift-6 | CleanShot | Text capture |

macOS shortcut reservations are automated.

Application-specific shortcut assignment remains manual because those applications own their settings and permissions.

## Homebrew 6 Trust

mise symlinks the root `Brewfile` to Homebrew's global `~/.homebrew/Brewfile`.

Official Homebrew taps require no additional trust.

The Infisical CLI, Maestro CLI, Sentry CLI, Pear Desktop, and FluxMarkdown come from third-party taps.

Each of those packages declares item-scoped `trusted: true` in `Brewfile`, so the repository does not trust the rest of its tap.

Any future third-party formula, cask, or command must follow the same narrow trust policy.

The generated `~/.homebrew/trust.json` file is runtime state and is intentionally ignored.

The existing Mac's trust file is not copied because it contains stale entries for tools that this setup no longer manages, including Oh My Posh and the old Homebrew Bun installation.

## Updating Tool Versions

Review available updates:

```sh
brew outdated
mise outdated
```

Update Homebrew packages:

```sh
brew update
brew upgrade
brew bundle --file Brewfile
brew bundle cleanup --force --formula --cask --tap --file Brewfile
```

Refresh locked mise versions without installing them:

```sh
MISE_SAFE=1 mise lock --bump
```

Review and commit `mise.lock` after testing.

The repository does not enable mise's strict `locked` mode yet because every managed backend must first have a complete macOS artifact URL and checksum in `mise.lock`.

Homebrew Bundle computes the recursive dependency closure of the managed formulae and the formula dependencies required by managed casks before cleanup.

It also preserves taps that provide a managed formula, cask, or retained dependency.

The cleanup is deliberately limited to Homebrew formulae, casks, and taps.

It does not use `--zap` and does not manage Mac App Store applications, editor extensions, or other package ecosystems.

## Repository Validation

This repository has no test suite, and one is not planned.

Inspect a change without touching the Mac:

```sh
./bootstrap.sh --dry-run
./scripts/doctor.sh
```

## Public Repository Safety

Never commit:

- Passwords or API tokens
- SSH private keys
- `~/.gitconfig.local`
- `~/.ssh/config.local`
- `.env` files
- `.npmrc`
- GitHub CLI authentication state
- Raycast exports
- Shell history
- Agent credentials or conversation histories
- Application databases, caches, or machine identifiers
- Generated Homebrew trust state

The setup uses exactly one managed file per tool and deliberately has no `*.local` override layer.

That includes `~/.claude/settings.local.json`, `~/.gitconfig.local`, `~/.ssh/config.local`, and `mise.local.toml`.

A setting that would otherwise land in a local override belongs in the managed file, so a new Mac reproduces it. The Claude plugin toggles and the reduced-motion preference were moved into `home/.claude/settings.json` for exactly that reason.

The matching `.gitignore` entries stay as a safety net against accidental commits, not as an invitation to create such files.

The repository does not yet prescribe a secrets backend.

The macOS Keychain, a dedicated CLI keychain, and Doppler will be evaluated before secret loading is automated.
