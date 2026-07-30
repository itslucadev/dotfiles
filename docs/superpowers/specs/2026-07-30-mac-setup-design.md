# Public macOS Dotfiles and React Native Setup

## Goal

This repository configures a new personal Apple Silicon Mac from a public Git repository.

The repository is prepared on the current Mac but its setup scripts are not executed there.

The first end-to-end run happens manually on a separate new Mac.

After that test succeeds, the current Mac can be reset and configured with the same repository.

## Principles

- mise is the central orchestrator.
- Homebrew owns formulae, casks, fonts, and supporting Mac App Store tooling.
- mise owns development runtimes and ecosystem CLIs.
- Bun installs all npm-backed global CLIs managed by mise.
- Dotfiles are applied with `mise bootstrap dotfiles`.
- macOS preferences are applied with `mise bootstrap macos defaults`.
- All setup operations must be idempotent.
- The setup must never prune or uninstall software automatically.
- The public repository must not contain secrets, tokens, private keys, account data, or machine-specific state.
- Manual authentication and permission steps belong in the README checklist.

## Repository Shape

```text
.
├── bootstrap.sh
├── apply.sh
├── Brewfile
├── mise.toml
├── mise.lock
├── home/
│   ├── .zshrc
│   └── .config/
├── scripts/
│   ├── install-raycast-beta.sh
│   ├── install-mas-apps.sh
│   └── doctor.sh
├── tests/
└── README.md
```

The exact dotfiles below `home/` will be added one configuration area at a time.

## Bootstrap Flow

`bootstrap.sh` is the only command required after cloning the repository on a new Mac.

It performs these stages:

1. Verify that the host is an Apple Silicon Mac.
2. Ensure the Xcode Command Line Tools are available.
3. Install Homebrew when it is missing.
4. Apply the repository `Brewfile`.
5. Trust the checked-out mise configuration.
6. Install mise runtimes and npm-backed CLIs.
7. Apply managed dotfiles.
8. Apply confirmed macOS defaults.
9. Install Raycast v2 Beta from Raycast's official distribution.
10. Attempt Mac App Store installations when the user is already signed in.
11. Print the remaining manual checklist and run the repository doctor.

The script must stop on real errors and explain actionable recovery steps.

Manual prerequisites such as an Apple Account login must not cause unrelated completed stages to be rolled back.

## Reapply Flow

`apply.sh` updates an already bootstrapped Mac.

It reapplies the `Brewfile`, installs the locked mise tools, reapplies dotfiles and macOS defaults, and runs the doctor.

It does not perform destructive Homebrew cleanup.

## Homebrew Ownership

The initial confirmed formulae include:

- fzf
- git
- lazygit
- mas
- mise
- neovim
- starship
- watchman

The initial confirmed casks include:

- AltTab
- Aqua Voice
- Caffeine
- CleanMyMac
- CleanShot
- Proton VPN
- Raycast v1
- Tailscale
- WezTerm
- Hack Nerd Font

RocketSim is installed through the Mac App Store because it has no Homebrew cask.

Raycast v2 Beta is installed separately from Raycast's official download because it has no official Homebrew cask.

The Beta installer verifies that the downloaded application has a valid Apple code signature before copying it into `/Applications`.

On unsupported macOS versions, the installer skips Raycast v2 Beta with an actionable message instead of breaking the remaining setup.

The target setup excludes Ghostty, KeepingYouAwake, Magnet, Parsec, Stats, and Xcode Beta.

## Raycast

Raycast v1 and Raycast v2 Beta stay installed side by side while v2 remains in beta.

Raycast v2 Beta is the primary launcher and window manager.

The README instructs the user to run Raycast's `Migrate from Raycast v1` command after onboarding.

The primary Raycast shortcut is Command-Space.

The native Spotlight shortcut is disabled to avoid a conflict.

Raycast configuration exports are not committed because they can contain clipboard history, AI conversations, authenticated extension data, and MCP configuration.

## Keyboard Shortcuts

- Raycast uses Command-Space.
- AltTab uses Command-Tab.
- Aqua Voice uses the Fn or Globe key as push-to-talk.
- CleanShot full-screen capture uses Command-Shift-3.
- CleanShot area capture uses Command-Shift-4.
- CleanShot all-in-one capture and recording uses Command-Shift-5.
- CleanShot text capture uses Command-Shift-6.
- Native macOS screenshot shortcuts are disabled to avoid conflicts.

Application-specific shortcuts that cannot be applied safely through public configuration are documented as manual steps.

## macOS Preferences

The initial confirmed preferences include:

- Use dark appearance.
- Use fast key repeat with a short initial delay.
- Disable press-and-hold character selection.
- Enable tap-to-click.
- Auto-hide the Dock.
- Place the Dock on the left.
- Use a small Dock size.
- Hide recent applications in the Dock.
- Show Finder items in list view.
- Show the Finder path bar.
- Show the Finder status bar.
- Show filename extensions.
- Disable the extension-change warning.
- Hide desktop icons.
- Auto-hide the menu bar.
- Store screenshots in a dedicated screenshots directory.
- Disable screenshot shadows.
- Avoid `.DS_Store` files on network shares and removable drives.

mise applies supported preferences through its typed macOS bootstrap sections.

Preferences that mise does not expose through friendly keys use explicit typed entries in `[bootstrap.macos.defaults]`.

Complex preferences that require plist arrays or dictionaries, including native screenshot shortcut changes, use small idempotent scripts invoked by mise tasks because the typed defaults backend intentionally supports only scalar values.

## Runtimes

Node.js uses the current LTS release instead of the newest current release because React Native tooling benefits from the LTS compatibility window.

Bun uses the latest release resolved and locked by mise.

The repository checks in `mise.lock` so a fresh Mac receives reviewed versions.

Updates happen explicitly and update the lockfile in Git.

## Global JavaScript CLIs

The mise npm backend uses Bun globally:

```toml
[settings.npm]
package_manager = "bun"
```

Each direct CLI has its own `npm:<package>` entry so mise can manage and verify it independently.

The initial retained CLI inventory is:

- `@earendil-works/pi-coding-agent`
- `@native-sdk/cli`
- `@playwright/cli`
- `@swmansion/argent`
- `@tobilu/qmd`
- `agent-device`
- `agentmail-cli`
- `eas-cli`
- `notebooklm-cli`
- `opensrc`
- `pyright`
- `react-doctor`
- `turbo`
- `typescript`
- `typescript-language-server`
- `vercel`

The setup excludes `@higgsfield/cli`, `firecrawl-cli`, `portless`, and `snapai`.

It also excludes the redundant global `npm` package and the non-CLI `undici` package.

Bun lifecycle script trust is not enabled globally.

If a reviewed CLI requires an installation script, that package receives a targeted `bun_args = "--trust"` setting after testing.

## React Native

The setup prepares the shared toolchain but does not create an application project.

The shared toolchain includes:

- Node.js LTS through mise
- Bun through mise
- EAS CLI through the mise npm backend
- Watchman through Homebrew
- Xcode stable
- Android Studio
- Java required by the selected React Native and Android toolchain
- CocoaPods when the selected workflow requires it
- RocketSim

Xcode Beta is intentionally excluded.

Xcode stable, its license, the active developer directory, simulators, Android SDK components, and emulator images require dedicated validation and some manual steps.

## Public Repository Safety

The repository ignores and scans for common private material, including:

- SSH private keys
- API tokens
- `.env` files
- npm authentication files
- GitHub CLI authentication data
- application databases and caches
- Raycast exports
- shell history
- agent conversation history
- machine-specific credentials

Agent instructions and preferences may be committed only when they contain no credentials, private conversations, or machine-specific identifiers.

Login sessions remain local and are recreated manually.

## Manual Checklist

The README contains an ordered checklist for:

- Apple Account and App Store login
- Xcode stable installation and first launch
- Xcode license acceptance and developer directory selection
- Git identity
- SSH key generation
- Adding the SSH public key to GitHub
- GitHub CLI authentication
- Raycast v1 to v2 migration
- Raycast, AltTab, CleanShot, Aqua Voice, CleanMyMac, Tailscale, Proton VPN, and RocketSim permissions
- Claude Code login
- Codex login
- Other installed agent and developer CLI logins
- Android Studio SDK and emulator setup
- Final doctor execution

No password, token, private key, or generated credential is committed.

## Permissions

The repository documents these expected macOS permissions:

- Accessibility for Raycast, AltTab, CleanShot, and Aqua Voice where requested
- Screen Recording for AltTab, CleanShot, and RocketSim where requested
- Microphone for CleanShot and Aqua Voice
- Full Disk Access for CleanMyMac where requested
- VPN or network extension approval for Tailscale and Proton VPN
- Notifications where useful

The scripts do not attempt to bypass macOS privacy protections or write directly to the TCC database.

## Validation

Repository tests validate:

- Shell syntax
- TOML syntax
- Brewfile syntax
- Required files and executable bits
- Duplicate or excluded packages
- Public-repository secret patterns
- Idempotent dry-run behavior where supported
- mise configuration and task discovery when mise is available

The first real end-to-end acceptance test runs manually on the separate new Mac.

The current Mac is reset only after that acceptance test succeeds.
