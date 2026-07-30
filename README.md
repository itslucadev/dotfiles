# macOS Dotfiles

This public repository configures Luca's personal Apple Silicon Mac for terminal work, AI agents, and React Native development.

mise is the central orchestrator.

Homebrew installs formulae, desktop applications, and fonts.

mise installs Node.js, Bun, Java, and global npm-backed CLIs, with Bun acting as their package manager.

## Status

The repository is prepared on the current Mac without running the setup there.

The first complete acceptance test must happen on a separate new Mac.

Only after that test succeeds should the current Mac be reset.

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

The scripts are idempotent and can be rerun after resolving a manual prerequisite.

## What the Bootstrap Does

The bootstrap:

- Verifies Apple Silicon macOS.
- Ensures the Xcode Command Line Tools are available.
- Installs Homebrew when necessary.
- Applies `Brewfile`.
- Installs GitHub CLI and the remaining native command-line tools.
- Installs locked mise runtimes and global CLIs.
- Applies the managed Zsh, Starship, and WezTerm dotfiles.
- Creates `~/Developer` as the shared project directory.
- Applies the confirmed macOS defaults.
- Reserves shortcuts for Raycast and CleanShot.
- Installs the signed Raycast v2 Beta beside Raycast v1.
- Attempts to install Xcode and RocketSim from the Mac App Store.
- Runs the setup doctor.

The bootstrap never runs Homebrew cleanup, uninstalls unmanaged applications, or writes directly to the macOS privacy database.

## Reapply Changes

After pulling repository changes, run:

```sh
./apply.sh
```

The equivalent mise task is:

```sh
mise run apply
```

Inspect the setup without changing the Mac:

```sh
./bootstrap.sh --dry-run
./apply.sh --dry-run
```

## Managed Applications

Homebrew installs:

- AltTab
- Android Studio
- Aqua Voice
- Caffeine
- CleanMyMac
- CleanShot
- Proton VPN
- Raycast v1
- Tailscale
- WezTerm
- Hack Nerd Font

The Mac App Store installs stable Xcode and RocketSim.

Raycast v2 Beta comes from Raycast's official signed disk image because no official Homebrew cask exists.

Ghostty, KeepingYouAwake, Magnet, Parsec, Stats, and Xcode Beta are intentionally excluded.

## Managed Runtimes and Global CLIs

mise manages:

- Node.js LTS
- Bun
- Zulu JDK 17
- Agent Device
- AgentMail CLI
- Argent
- EAS CLI
- Native SDK CLI
- NotebookLM CLI
- OpenSrc
- Pi Coding Agent
- Playwright CLI
- Pyright
- QMD
- React Doctor
- Turbo
- TypeScript
- TypeScript Language Server
- Vercel CLI

All npm-backed CLIs are installed by Bun through mise.

Portless, Higgsfield CLI, SnapAI, and Firecrawl CLI are intentionally excluded.

Global `npm` and `undici` are not installed as separate tools.

## Shell and Terminal

The interactive stack is:

- Zsh as the shell.
- Antidote as the Zsh plugin manager.
- Starship as the prompt renderer.
- WezTerm as the primary terminal.

Oh My Zsh and Oh My Posh are not installed.

Antidote loads:

- Zsh Completions
- ez-compinit
- FZF Tab
- Zsh Autosuggestions
- Zsh You Should Use
- Zsh Bat
- Zsh Syntax Highlighting

The shell also configures FZF, Eza, Zoxide, Bat, Neovim, Android SDK paths, and mise activation.

The `dev` alias opens `~/Developer`.

The `appzudio` alias opens `~/Developer/appzudio`.

WezTerm starts from Kun Chen's Rose Pine Moon styling with Hack Nerd Font, transparency, blur, minimal tabs, and resize-only window decorations.

Ghostty remains a separate configuration decision and is not installed yet.

## Manual Setup Checklist

### Apple Account and Mac App Store

- [ ] Sign in to the Mac App Store.
- [ ] Claim stable Xcode and RocketSim if the account has never downloaded them.
- [ ] Run `mise run apps:mas`.

### Xcode

- [ ] Launch `/Applications/Xcode.app` once and allow it to install additional components.
- [ ] Accept the Xcode license with `sudo xcodebuild -license accept`.
- [ ] Select stable Xcode with `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`.
- [ ] Install the required iOS simulator runtime in Xcode Settings under Platforms or Components.
- [ ] Keep Xcode Beta out of the active developer path.

### Android Studio

- [ ] Complete the Android Studio setup wizard.
- [ ] Install Android SDK Platform 35 for Android 15.
- [ ] Install Android SDK Build-Tools 36.0.0.
- [ ] Install Android SDK Command-line Tools latest.
- [ ] Install Android Emulator and Platform Tools.
- [ ] Create an Apple Silicon Google APIs ARM 64 virtual device.
- [ ] Confirm that the SDK is stored at `~/Library/Android/sdk`.

The shell configuration exposes `ANDROID_HOME`, `emulator`, and `platform-tools`.

mise exposes `JAVA_HOME` for Zulu JDK 17 when its shell activation is active.

### Git and GitHub

- [ ] Configure the Git name with `git config --global user.name "Your Name"`.
- [ ] Configure the Git email with `git config --global user.email "you@example.com"`.
- [ ] Generate an SSH key with `ssh-keygen -t ed25519 -C "you@example.com"`.
- [ ] Add the public key from `~/.ssh/id_ed25519.pub` to GitHub.
- [ ] Test SSH with `ssh -T git@github.com`.
- [ ] Authenticate GitHub CLI with `gh auth login`.

Never commit the SSH private key or GitHub CLI authentication files.

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

- [ ] Run Claude Code and complete its login.
- [ ] Run Codex and complete its login.
- [ ] Authenticate EAS with `eas login`.
- [ ] Authenticate Vercel with `vercel login`.
- [ ] Authenticate AgentMail if it is used.
- [ ] Complete any NotebookLM CLI browser login.
- [ ] Configure other agent tools without committing their credentials or histories.

### Final Verification

- [ ] Open a new WezTerm window so the managed shell configuration is active.
- [ ] Run `mise doctor`.
- [ ] Run `mise run doctor`.
- [ ] Run `mise run test`.
- [ ] Build and launch one React Native project on an iOS Simulator.
- [ ] Build and launch one React Native project on the Android emulator.
- [ ] Reboot once and verify login items, shortcuts, VPNs, and permissions.

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
```

Refresh locked mise versions without installing them:

```sh
MISE_SAFE=1 mise lock --bump
```

Review and commit `mise.lock` after testing.

Do not run `brew bundle cleanup` as part of this repository.

## Repository Validation

Run:

```sh
./tests/test.sh
```

The tests check shell and TOML syntax, Brewfile parsing, executable permissions, dry-run paths, excluded packages, destructive package-manager commands, common secret patterns, and whitespace.

They do not install applications or apply macOS settings.

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

Use `~/.zshrc.local` for non-secret machine-specific shell settings.

The repository does not yet prescribe a secrets backend.

The macOS Keychain, a dedicated CLI keychain, and Doppler will be evaluated before secret loading is automated.

## Design

The approved architecture is documented in [docs/superpowers/specs/2026-07-30-mac-setup-design.md](docs/superpowers/specs/2026-07-30-mac-setup-design.md).
