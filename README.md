<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://shieldcn.dev/header/graph.svg?title=macOS%20Dotfiles&subtitle=One%20bootstrap%20command%2C%20orchestrated%20by%20mise%20and%20Homebrew&logo=apple&logoColor=c4a7e7&bg=232136&titleColor=e0def4&subtitleColor=908caa&accent=c4a7e7&align=left&font=inter" />
    <img alt="macOS Dotfiles - one bootstrap command, orchestrated by mise and Homebrew" src="https://shieldcn.dev/header/graph.svg?title=macOS%20Dotfiles&subtitle=One%20bootstrap%20command%2C%20orchestrated%20by%20mise%20and%20Homebrew&logo=apple&logoColor=907aa9&bg=faf4ed&titleColor=575279&subtitleColor=797593&accent=907aa9&align=left&font=inter" />
  </picture>
</p>

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://shieldcn.dev/badge/platform-Apple%20Silicon.svg?variant=secondary&color=2a273f&logo=apple&logoColor=c4a7e7&mode=dark" />
    <img alt="platform: Apple Silicon" src="https://shieldcn.dev/badge/platform-Apple%20Silicon.svg?variant=secondary&logo=apple&logoColor=907aa9&mode=light" />
  </picture>
  <a href="https://mise.jdx.dev">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://shieldcn.dev/badge/orchestrator-mise.svg?variant=secondary&color=2a273f&logo=ri:RiStackLine&logoColor=9ccfd8&mode=dark" />
      <img alt="orchestrator: mise" src="https://shieldcn.dev/badge/orchestrator-mise.svg?variant=secondary&logo=ri:RiStackLine&logoColor=286983&mode=light" />
    </picture>
  </a>
  <a href="https://brew.sh">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://shieldcn.dev/badge/packages-Homebrew.svg?variant=secondary&color=2a273f&logo=homebrew&logoColor=f6c177&mode=dark" />
      <img alt="packages: Homebrew" src="https://shieldcn.dev/badge/packages-Homebrew.svg?variant=secondary&logo=homebrew&logoColor=b4637a&mode=light" />
    </picture>
  </a>
  <a href="https://www.zsh.org">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://shieldcn.dev/badge/shell-Zsh.svg?variant=secondary&color=2a273f&logo=zsh&logoColor=ea9a97&mode=dark" />
      <img alt="shell: Zsh" src="https://shieldcn.dev/badge/shell-Zsh.svg?variant=secondary&logo=zsh&logoColor=d7827e&mode=light" />
    </picture>
  </a>
  <a href="https://github.com/phoenix-error/dotfiles/commits/main">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://shieldcn.dev/github/last-commit/phoenix-error/dotfiles.svg?variant=secondary&color=2a273f&mode=dark" />
      <img alt="last commit" src="https://shieldcn.dev/github/last-commit/phoenix-error/dotfiles.svg?variant=secondary&mode=light" />
    </picture>
  </a>
</p>

This public repository configures Luca's personal Apple Silicon Mac for terminal work, AI agents, and React Native development.

mise is the central orchestrator.

Homebrew installs formulae, desktop applications, and fonts.

mise installs Node.js, Bun, Python, Java, native developer tools, and global npm-backed CLIs, with Bun acting as the npm package manager.

Fuzzy versions must be at least seven days old before mise selects them, which limits exposure to brand-new supply-chain releases.

Each machine keeps its own `mise.lock`, which mise writes and this repository does not track.

## At a Glance

| Layer | Owned by | Declared in |
| --- | --- | --- |
| Applications, fonts, native CLIs | Homebrew | `Brewfile` |
| Mac App Store applications | mas | `Brewfile.mas` |
| Runtimes and global CLIs | mise | `mise.toml` |
| Dotfiles and macOS defaults | mise | `mise.toml` and `home/` |
| Setup entry point | Bash | `bootstrap.sh` |

## Contents

**Setup**
[Quick Start](#quick-start-on-a-new-mac) ·
[What the Bootstrap Does](#what-the-bootstrap-does) ·
[Manual Interaction Gates](#manual-interaction-gates) ·
[Declarative Ownership](#declarative-ownership) ·
[Reapply Changes](#reapply-changes)

**Inventory**
[Managed Applications](#managed-applications) ·
[Runtimes and Global CLIs](#managed-runtimes-and-global-clis) ·
[Shell and Terminal](#shell-and-terminal) ·
[VS Code and Cursor](#vs-code-and-cursor) ·
[Agent Configuration](#agent-configuration) ·
[Global Agent Skills](#global-agent-skills)

**Operations**
[Git and SSH](#git-and-ssh) ·
[Secrets with Infisical](#secrets-with-infisical) ·
[Manual Setup Checklist](#manual-setup-checklist) ·
[Safe Test Strategy](#safe-test-strategy) ·
[Keyboard Shortcuts](#keyboard-shortcuts) ·
[Homebrew 6 Trust](#homebrew-6-trust) ·
[Updating Tool Versions](#updating-tool-versions) ·
[Repository Validation](#repository-validation) ·
[Public Repository Safety](#public-repository-safety)

## Status

> [!IMPORTANT]
> The repository is prepared on the current Mac without running the setup there.
> No real setup command has been run on the current Mac while preparing this repository.

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

The global agent skills are installed by hand from [docs/agent-skills.md](docs/agent-skills.md), which records which skills belong on the machine and the exact command for each source.

## What the Bootstrap Does

The bootstrap:

- Verifies Apple Silicon macOS.
- Ensures the Xcode Command Line Tools are available.
- Installs Homebrew when necessary.
- Applies `Brewfile`.
- Removes Homebrew formulae, casks, and taps that are not required by `Brewfile`.
- Trusts the repository `mise.toml`.
- Installs the locked language runtimes, then the locked global CLIs.
- Applies the managed Zsh, Starship, WezTerm, Ghostty, Herdr, Git, SSH, editor, Claude, and global agent dotfiles, and links the repository `Brewfile` to Homebrew's global `~/.homebrew/Brewfile`.
- Installs the Herdr agent integrations for Claude Code, Codex, Cursor, Oh My Pi, and Pi.
- Installs the saved VS Code and Cursor extensions through their native command-line interfaces.
- Creates `~/Developer` and applies the confirmed macOS defaults.
- Reserves shortcuts for Raycast and CleanShot.
- Creates or reuses one Ed25519 key for GitHub authentication and commit signing, loads it through the macOS Keychain, and maintains the local allowed signers file.
- Installs the signed Raycast v2 Beta beside Raycast v1.
- Installs the managed Mac App Store applications after any required App Store interaction is complete.
- Runs the setup doctor.

It does not install agent skills. Those are a personal, fast-moving choice and are listed in [docs/agent-skills.md](docs/agent-skills.md) for manual installation.

The runtimes install before the remaining CLIs because the other backends depend on them: the pipx backend needs uv, and every npm-backed tool needs bun as its package manager.

The four stages that wait for a person run together near the end, so everything between Homebrew and the reserved shortcuts completes unattended.

The Homebrew reconciliation uses regular cask uninstall behavior and never passes `--zap`, so application data and shared support files are preserved.

It does not remove manually installed applications outside Homebrew or write directly to the macOS privacy database.

## Manual Interaction Gates

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
- `mise.lock` contains the resolved mise tool versions. Only mise writes it, it is local to each machine, and it is not tracked.
- `home/` contains public configuration that mise symlinks into the home directory.
- `home/.zsh_plugins.txt` is the only source of Zsh plugins.

`bootstrap.sh` is the only setup entry point.

It installs the first dependencies needed before mise is available, then runs the remaining stages in the required order, because Homebrew must install mise before mise can orchestrate the rest.

It calls six helper scripts that can change the Mac or connected accounts:

- `scripts/configure-macos.sh` owns the dynamic screenshot path and nested `AppleSymbolicHotKeys` dictionary that mise macOS defaults cannot represent correctly.
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

Homebrew installs these applications:

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
- Linear
- LocalSend
- Minecraft
- MultiViewer
- Obsidian
- OpenUsage
- Pear Desktop for YouTube Music
- Proton VPN
- Raycast v1
- Spark
- Tailscale
- TextMate
- Tower
- Visual Studio Code
- WezTerm
- WhatsApp

Homebrew also installs Claude Code and the Codex CLI as casks.

Homebrew installs these command-line tools: Agent Browser, App Store Connect CLI, AXe, BFG, CocoaPods, Fallow, Fastlane, fd, Git LFS, Gitleaks, the Infisical CLI, jq, LazyGit, the Linear CLI, the Maestro CLI, Mole, Oh My Pi, the Pi coding agent, the Resend CLI, ripgrep, the Sentry CLI, the Sentry Wizard, Tmux, Watchman, and YouTube-DLP.

The interactive shell tools Antidote, bat, eza, fd, FZF, ripgrep, Starship, and Zoxide are covered in the shell section below.

The Mac App Store installs Actions, Folder Quick Look, Helm, Obsidian Web Clipper, RocketSim, Timepage, and stable Xcode.

Apple Developer, TestFlight, Notability, Magnet, Mela, Arc, Slack, Figma, the Affinity suite, GitHub Desktop, Parsec, Proton Pass, KeepingYouAwake, Stats, and Stremio are deliberately excluded. Raycast Window Management replaces Magnet.

Only Hack Nerd Font is installed. The Fira Code, JetBrains Mono, Meslo, and Symbols Only Nerd Fonts are deliberately excluded.

Raycast v2 Beta comes from Raycast's official signed disk image because no official Homebrew cask exists.

The setup does not install Rosetta 2. No managed cask declares an Intel requirement, and Minecraft Java Edition has shipped a native Apple Silicon launcher since version 1.19 in June 2022.

GatherOS, Maestro Studio, Recordly, and SimCam are direct-download applications covered by the manual setup checklist.

Sentry Spotlight and Xcode Beta are excluded as well.

## Managed Runtimes and Global CLIs

mise manages:

- Node.js LTS
- Bun
- Python 3.12
- uv
- Ruff
- Zulu JDK 17
- Agent Device
- Argent
- Biome
- Chrome DevTools axi
- Context7 CLI
- EAS CLI
- gh-axi
- Lavish CLI
- NotebookLM CLI
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

AgentMail CLI, OpenSrc, the Native SDK CLI, the Playwright CLI, Portless, Higgsfield CLI, SnapAI, and Firecrawl CLI are intentionally excluded.

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
- Zsh SSH

The shell also configures FZF, Eza, Zoxide, Bat, Android SDK paths, and mise activation.

Starship uses the official Rose Pine Moon palette so the prompt matches WezTerm, Ghostty, Herdr, VS Code, and Cursor.

The `dev` alias opens `~/Developer`.

The bootstrap creates `~/Developer/appzudio` as the shared parent directory for all AppZudio projects.

The `appzudio` alias opens that parent directory.

Zsh plugins are managed only by Antidote through `home/.zsh_plugins.txt`.

Repository agent instructions explicitly prohibit installing individual Zsh plugins through Homebrew, Oh My Zsh, or manual clones.

WezTerm starts from Kun Chen's Rose Pine Moon styling with Hack Nerd Font, transparency, blur, minimal tabs, and resize-only window decorations.

Ghostty uses the same Rose Pine Moon theme, Hack Nerd Font, 14-point font size, 0.8 background opacity, and blur level 50.

Its configuration file is named `config` with no extension, because that is the only name Ghostty reads inside `~/.config/ghostty`.

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

The shared React and React Native setup includes Biome, Prettier, ESLint, Tailwind CSS IntelliSense, Pretty TypeScript Errors, Error Lens, Path IntelliSense, Auto Rename Tag, Import Cost, Indent Rainbow, and the ES7+ React snippets.

Both editors also receive GitLens and the Claude Code extension.

Modernized is the one VS Code specific addition beyond Pylance. It is published only on the Visual Studio Marketplace, so Cursor cannot install it.

Swift, Java, Kotlin, clangd, LLDB, and the .NET extensions are deliberately excluded. Xcode owns Swift and Objective-C, Android Studio owns Java and Kotlin, and both are part of this setup.

Fallow reports unused code, circular dependencies, duplication, complexity hotspots, and architecture boundary violations in TypeScript and JavaScript.

Homebrew installs its `fallow` command, and both editors install the `fallow-rs.fallow-vscode` extension, which is published on the Visual Studio Marketplace and on Open VSX.

The Homebrew formula builds only the CLI crate, so it does not provide `fallow-lsp`. The language server therefore resolves a project-local install, and every project that wants editor diagnostics should add `fallow` as a development dependency at the matching version.

The extension keeps its `fallow.autoDownload` default, so it fetches a managed language server when a project has none.

Biome formats JavaScript, JSX, TypeScript, TSX, JSON, and JSONC on save.

Prettier formats CSS, SCSS, HTML, GraphQL, Markdown, and YAML on save.

Each project should still declare its own Biome, Prettier, and ESLint dependencies and configuration so the repository controls exact tool versions and rules.

Both editors deliberately run the same extension set.

`home/.config/editors/extensions.txt` is the shared inventory and holds every extension that both editors can install.

The two editor-specific inventories exist only for extensions that genuinely cannot be shared. Today that is a single pair: Microsoft licenses Pylance for official Microsoft products only, so VS Code gets `ms-python.vscode-pylance` and Cursor gets its replacement `anysphere.cursorpyright`.

Add a new extension to the shared inventory unless installing it in the other editor is impossible.

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

Homebrew installs every coding agent: Claude Code and Codex as casks, the Pi coding agent and Oh My Pi as formulae.

Agent binaries update themselves at runtime, so a mise lockfile could not hold their versions and the seven-day minimum release age would buy nothing. Anthropic also deprecated the Claude Code npm package in January 2026 with version 2.1.15 in favour of the native binary.

Every Homebrew cask and formula pins the exact release artifact with a SHA-256 checksum, which a vendor install script piped into a shell cannot offer.

Claude Code updates itself into `~/.local/share/claude`. That directory belongs to its own updater and is not managed by this repository.

Oh My Pi comes from `can1357/tap` as the `omp` formula, a native binary at version 17. Its npm package stalled at 0.2.0 and is not the same distribution.

Claude agent teams use Tmux split panes.

Herdr remains the primary multiplexer for persistent agent sessions.

Tmux is installed as a dedicated dependency for Claude's split-pane team display and does not currently have a managed configuration file.

Claude Code starts in Auto mode, which runs tasks without routine permission prompts while retaining Claude's background safety checks.

Auto mode availability depends on the active Claude plan, model, provider, and organization settings.

The Pyright and TypeScript LSP plugins remain enabled so Claude receives diagnostics, type information, definitions, and references while editing supported projects.

Claude authentication, caches, conversation history, local settings, and generated plugin state are not tracked.

The [ChatGPT desktop application](https://learn.chatgpt.com/docs/app) includes the Codex desktop experience, and Homebrew installs the standalone Codex CLI beside it.

Oh My Pi extends the Pi coding agent into a multi-agent orchestration setup, and Herdr installs the matching integrations for Claude Code, Codex, Cursor, Oh My Pi, and Pi.

The Claude Codex plugin and its marketplace remain excluded.

The global agent instructions tell agents to use PostHog CLI for deterministic PostHog work without storing its credentials in the repository.

## Global Agent Skills

The setup does not install agent skills.

Skill sources are renamed, split, and retired far faster than the rest of this inventory, and a stale entry fails the whole run without adding anything a fresh Mac needs to work.
They are installed by hand instead.

[docs/agent-skills.md](docs/agent-skills.md) is the record of which skills belong on the machine.
It lists every skill with its purpose, the exact `bunx --bun skills@1.5.21` command for each source, what is deliberately left out, and how to verify the result.

The repository does not copy local plugin caches or private skill folders.

The Claude plugins enabled in `home/.claude/settings.json` ship their own skills, which that file does not govern.

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
- [ ] Open a React Native project and confirm that Biome, Prettier, ESLint, and Tailwind activate only where their project configuration applies.
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
- [ ] Authenticate Fallow if a project uses the optional paid runtime layer.
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
- [ ] Install the global agent skills by hand from [docs/agent-skills.md](docs/agent-skills.md).
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

The AXe CLI, Infisical CLI, Linear CLI, Maestro CLI, Oh My Pi, Resend CLI, Sentry CLI, Sentry Wizard, Pear Desktop, and FluxMarkdown come from third-party taps.

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

Refresh the local resolved mise versions without installing them:

```sh
MISE_SAFE=1 mise lock --bump
```

`mise.lock` is not tracked. Only mise can write it, every entry in `mise.toml` is a fuzzy version, and a committed copy went stale within months without ever having been the source of truth. `mise.toml` is that source, and the seven-day minimum release age is what actually limits exposure.

Each machine therefore resolves and keeps its own lockfile.

The repository does not enable mise's strict `locked` mode, which would require a tracked lockfile with a complete macOS artifact URL and checksum for every managed backend.

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
