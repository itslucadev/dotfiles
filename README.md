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

mise installs Node.js, Bun, pnpm, Python, Java, native developer tools, and global npm-backed CLIs, with Bun acting as the npm package manager.

Fuzzy versions must be at least one day old before mise selects them, which limits exposure to brand-new supply-chain releases.

Each machine keeps its own `mise.lock`, which mise writes and this repository does not track.

## At a Glance

| Layer | Owned by | Declared in |
| --- | --- | --- |
| Applications, fonts, native CLIs | Homebrew | `Brewfile` |
| Mac App Store applications | mas | `Brewfile.mas` |
| Runtimes and global CLIs | mise | `mise.toml` |
| Dotfiles and macOS defaults | mise | `mise.toml` and `home/` |
| Dock layout | you, by task | `dock.txt`, [see why](#the-dock) |
| Bare-metal initialization | Bash | `bootstrap.sh` |
| Managed setup stages | mise | `mise.toml` task `setup` and `[bootstrap.hooks]` |
| Git identity and SSH | you, by hand | nothing here, [see why](#declarative-ownership) |
| Every manual step on a new Mac | you, by hand | [`setup-guide.html`](setup-guide.html) |

## Contents

**Walkthrough**
[setup-guide.html](setup-guide.html) is the step-by-step guide for a new Mac, including the global agent skills

**Setup**
[Setting Up a New Mac](#setting-up-a-new-mac) ·
[What the Two Commands Do](#what-the-two-commands-do) ·
[Manual Interaction Gates](#manual-interaction-gates) ·
[Declarative Ownership](#declarative-ownership) ·
[Reapply Changes](#reapply-changes)

**Inventory**
[Managed Applications](#managed-applications) ·
[The Dock](#the-dock) ·
[Runtimes and Global CLIs](#managed-runtimes-and-global-clis) ·
[Local Development URLs](#local-development-urls) ·
[Mobile Toolchains](#mobile-toolchains) ·
[Shell and Terminal](#shell-and-terminal) ·
[VS Code and Cursor](#vs-code-and-cursor) ·
[Agent Configuration](#agent-configuration)

**Operations**
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

## Setting Up a New Mac

> [!IMPORTANT]
> **[setup-guide.html](setup-guide.html) is the instruction manual, not this file.**
>
> It is an offline, checkable guide covering every step in thirteen phases, from macOS onboarding through the final reboot, and it remembers which boxes are already ticked.
> Open it first and work through it to the end.
>
> This README documents what the repository owns and why it is built the way it is.
> It deliberately does not repeat the walkthrough.

Clone the repository to the fixed path, then initialize the Mac:

```sh
mkdir -p ~/github/phoenix-error
git clone https://github.com/phoenix-error/dotfiles.git ~/github/phoenix-error/dotfiles
cd ~/github/phoenix-error/dotfiles

./bootstrap.sh
```

Run both commands as the ordinary user account and never with `sudo`.
`bootstrap.sh` declines a privileged run and asks for the password once, at the single point that needs administrator rights.

Open a new terminal, then apply the setup:

```sh
mise run setup
```

Those two commands are the whole automated part.
Everything else is manual on purpose and is walked through in the setup guide: Xcode Command Line Tools, Apple Account and Mac App Store, Xcode, Android Studio, Git identity and GitHub SSH, privacy permissions, application logins, keyboard shortcuts, and the smoke tests.

The `setup` task pauses at every step that needs a person, explains what to do, verifies the result, and continues.
Both commands are idempotent and can be rerun after resolving a manual prerequisite.

The new terminal is needed because `bootstrap.sh` links `~/.zprofile`, `~/.zshrc`, and `~/.zsh_plugins.txt` as its last step, which is what puts Homebrew and mise on `PATH`.
If that step reported that it could not link them, the Mac already has hand-written files there.
Nothing is lost, and the setup runs as `~/.local/bin/mise run setup` instead.

The fixed clone path allows the repository `mise.toml` to serve as the global mise configuration while keeping dotfile sources predictable.

Cloning needs no Git identity and no SSH key, because the repository is public and the command above clones over HTTPS.
Both are created by hand later, at the gate the setup opens for them, and the setup guide carries the whole sequence.

The global agent skills are installed by hand from the Agents phase of [setup-guide.html](setup-guide.html), which carries the install commands and the sources that arrive another way.

## What the Two Commands Do

`./bootstrap.sh` is bare-metal initialization and installs only what cannot come from managed configuration, because nothing that could install it exists yet:

- Verifies Apple Silicon macOS, the expected clone path, and that it was not started as root.
- Ensures the Xcode Command Line Tools are available.
- Installs Homebrew from `https://brew.sh` when necessary, after requesting administrator rights once.
- Installs mise into `~/.local/bin/mise` when necessary, with the committed copy of the `https://mise.run` installer in `scripts/setup-mise.sh`.
- Trusts the repository `mise.toml`.
- Links `~/.zprofile`, `~/.zshrc`, and `~/.zsh_plugins.txt`, the files that put Homebrew and mise on `PATH` and that the shell configuration reads.

Then it stops. It installs no declared package and applies no other configuration.

Exactly one of those steps needs administrator rights, and the script escalates only there.
Homebrew owns `/opt/homebrew`, which only root can create, so its installer escalates with `sudo` itself and refuses to be run as root at all.
`bootstrap.sh` therefore asks for the password with `sudo -v` right before it starts the installer, and runs the installer unprivileged.

Everything else stays unprivileged on purpose.
`xcode-select --install` only asks macOS to open the installer dialog, and the privileged part runs in the system installer.
The mise installer writes to `~/.local/bin`, and `mise trust` and the dotfile links write to the mise trust store and the home directory.
A run under `sudo` would leave all of that owned by root and break every later `mise run setup`, so the script refuses a privileged run before it changes anything.

mise.run is the method the mise documentation recommends for macOS, with Homebrew listed only as the alternative.
The official binaries are built with the optimized release profile, are updatable with `mise self-update`, and are available immediately after a release.

The installer itself is committed as `scripts/setup-mise.sh` rather than downloaded on every fresh Mac.
It carries the release checksums, so a copy that was reviewed once in a diff is a smaller trust surface than a script fetched unseen and piped into a shell.
The mise documentation recommends the same for exactly that reason.
The version it pins is irrelevant here, because the setup runs `mise self-update` before anything else.
Refresh the copy with `mise run update:mise-installer` and review the diff.

Linking those three shell files is the last initialization step rather than a setup stage because neither Homebrew nor mise is on a fresh Mac's default `PATH`, and those three files are what put them there.
It runs without `--force`, so mise refuses to replace a hand-written `~/.zshrc` instead of overwriting it.
In that case `bootstrap.sh` says so, and the setup runs once as `~/.local/bin/mise run setup`.

The `https://mise.run/zsh` installer variant, which appends the activation line to `~/.zshrc` itself, is deliberately not used.
That file is a managed symlink here, and a foreign edit would make `mise bootstrap dotfiles apply` refuse the conflict on every run.

mise is deliberately absent from `Brewfile`.
It has to exist before the `Brewfile` is applied, and `brew bundle cleanup` must never be able to remove the binary that is driving the setup.
The check targets the install path rather than `PATH`, so a Mac that still carries an older Homebrew mise gets the self-managed copy before cleanup removes the Homebrew one.

The Composio CLI is also absent from `Brewfile` and `mise.toml`.
It has no Homebrew formula, and the official installer is the supported channel.
`scripts/setup-composio.sh` runs the committed installer in `scripts/install-composio.sh` with `COMPOSIO_INSTALL_SHELL=none` so it cannot edit the managed `~/.zshrc`, then configures the Claude Code and Codex plugins.
`~/.local/bin` is already on `PATH`.
Refresh the committed installer with `mise run update:composio-installer` and review the diff.
Login stays in the Agents phase of the setup guide.

The `setup` task in `mise.toml` updates mise itself and then runs `mise bootstrap --yes`, which owns the stage order:

- Updates mise itself, because `Brewfile` no longer keeps it current.
- Applies `Brewfile`.
- Removes Homebrew formulae, casks, and taps that are not required by `Brewfile`.
- Pauses for the manual Git identity and GitHub SSH setup, then verifies them before continuing.
- Resolves existing dotfile conflicts before linking.
- Applies the managed Zsh, Starship, WezTerm, Ghostty, Herdr, editor, Claude, and Shared Core dotfiles, and links the repository `Brewfile` to Homebrew's global `~/.homebrew/Brewfile`.
- Creates `~/Developer/appzudio` and applies the confirmed macOS defaults.
- Installs the locked language runtimes, then the locked global CLIs.
- Pauses for the coding agent sign-ins, then verifies them before continuing.
- Converges Oh My Pi settings from the snapshot.
- Installs the Composio CLI and configures its Claude Code and Codex plugins.
- Installs the Herdr agent integrations for Claude Code, Codex, Cursor, Oh My Pi, OpenCode, and the Grok CLI.
- Installs the managed Mac App Store applications after any required App Store interaction is complete.
- Installs the daily tool updater and the evening Oh My Pi settings capture.
- Installs the delegated ssh-agent socket.
- Runs the setup doctor.

Dotfiles, macOS defaults, and tools are native `mise bootstrap` phases, and mise converges them itself.
The remaining stages are `[bootstrap.hooks]` entries in `mise.toml`, which run before or after a phase and halt the setup when they fail.

Homebrew stays in `Brewfile` instead of moving into `[bootstrap.packages]`.
mise only converges forward and never removes a package that the configuration stopped declaring, while `brew bundle cleanup` does exactly that.
The Mac App Store applications stay in `Brewfile.mas` for the same reason, and because their installation needs a gate for App Store sign-in and claiming.

It does not install agent skills. Those are a personal, fast-moving choice and are covered in the Agents phase of [setup-guide.html](setup-guide.html) for manual installation.

The runtimes install before the remaining CLIs because the other backends depend on them: the pipx backend needs uv, and every npm-backed tool needs bun as its package manager.

After the Git and SSH gate, the remaining unattended stages run until the coding agent sign-ins, and then again until the Mac App Store installs, which both need a person at the keyboard.

The coding agent gate sits directly before the Herdr integrations, because Herdr can only hook an agent that has created its configuration directory, and an agent does that on its first run.
The agents themselves arrive with `Brewfile` in the same run, so the sign-ins cannot happen any earlier than this.

The Homebrew reconciliation uses regular cask uninstall behavior and never passes `--zap`, so application data and shared support files are preserved.

It does not remove manually installed applications outside Homebrew or write directly to the macOS privacy database.
It does clear the Gatekeeper quarantine attribute from Homebrew-installed cask applications after `Brewfile` is applied, because Homebrew 6 no longer offers `--no-quarantine` and every cask download would otherwise ask "Are you sure you want to open it?" again.


## Manual Interaction Gates

The setup treats every manual prerequisite for a later automated stage as a gate.

In an interactive terminal, it pauses at the gate, explains the required action, waits for completion, verifies the result, and only then continues.

In a non-interactive environment, it stops with Exit code 2 and prints the command that must be rerun after the action is complete.
That command is `./bootstrap.sh` for the two initialization gates, `mise run setup` for the Git and SSH gate and the coding agent gate, and `mise run apps:mas` for the Mac App Store gate.

The gated interactions are:

- Finishing the Xcode Command Line Tools installer.
- Confirming administrator rights before Homebrew creates `/opt/homebrew`, which needs `sudo -v` first in a non-interactive environment.
- Completing the manual Git identity and GitHub SSH checklist after `Brewfile` installs Git, including comparing GitHub's SSH host fingerprint on the first connection.
- Signing in to Claude Code, Codex, the Cursor CLI, Oh My Pi, OpenCode, and the Grok CLI, so Herdr can install its integration for each of them.
- Signing in to the Mac App Store and claiming applications that the Apple Account has never downloaded.

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
- `dock.txt` owns the managed Dock.
- Git owns nothing here. `~/.gitconfig`, `~/.ssh/config`, and anything under `~/.config/git/` are written by hand. A managed `~/.gitconfig` carrying an identity would be applied long before the person it names has decided on one, and configuration that only works once a later stage has run is configuration this repository should not own. SSH private keys, `known_hosts`, `authorized_keys`, and authentication state are never copied here either. Commit signing is not managed here either: nothing depends on it, and GitHub accepts unsigned pushes. The setup guide documents SSH commit signing with the same key as an optional step.

`bootstrap.sh` runs once per Mac, or again after a macOS upgrade removed the Xcode Command Line Tools.

`mise run setup` is the entry point for everything else, including every rerun.

- `scripts/install-homebrew-packages.sh` applies `Brewfile`, removes what it no longer declares, and clears Gatekeeper quarantine from the installed cask apps.
- `scripts/require-git-and-github.sh` gates the manual Git identity and GitHub SSH setup.
- `scripts/resolve-dotfile-conflicts.sh` gates existing files before the dotfiles phase.
- `scripts/require-coding-agents.sh` gates the coding agent sign-ins that Herdr depends on.
- `scripts/install-herdr-integrations.sh` asks Herdr to install its own agent hooks.
- `scripts/setup-omp-agent.sh` converges the desired Oh My Pi settings from `scripts/omp-agent-settings.json`.
- `scripts/sync-omp-agent-settings.sh` captures live Oh My Pi settings into that snapshot.
- `scripts/setup-omp-sync.sh` installs the 20:00 launchd agent for that capture.
- `scripts/setup-composio.sh` installs the Composio CLI and converges the Claude Code and Codex plugins.
- `scripts/install-mas-apps.sh` installs the declared Mac App Store applications and gates account interaction.
- `scripts/setup-ssh-agent.sh` keeps ssh-agent on `~/.ssh/agent.sock` and points `~/.ssh/config` at that socket so coding agents can SSH without the private key.
- `scripts/setup-autoupdate.sh` installs the daily tool updater.
- `scripts/sync-dock.sh` applies and exports the managed Dock from `dock.txt`.

The read-only `scripts/doctor.sh` inspects the result without configuring the Mac.

This repository has no test suite. Configuration is verified with `./bootstrap.sh --dry-run` and the setup doctor.

All scalar macOS settings with static values use mise's friendly or raw defaults sections.

Screenshot folder and keyboard-shortcut conflicts stay manual because CleanShot and Raycast own those settings, and nested `AppleSymbolicHotKeys` entries are not expressible as scalar mise defaults.

## Reapply Changes

After pulling repository changes, reapply the managed stages:

```sh
mise run setup
```

Every stage is idempotent, so desired packages, applied dotfiles, and applied macOS defaults are left alone.

Homebrew formulae, casks, and taps that are neither declared nor required as dependencies are removed.

The task is deliberately named `setup`.

mise reserves the `bootstrap` name for its built-in bootstrap pipeline and automatically runs a task with that name afterward, so using the same name here would repeat the repository setup.

`./bootstrap.sh` is not part of a rerun. It only reverifies the Xcode Command Line Tools, Homebrew, and mise, which a working Mac already has.

Inspect the three initialization steps without changing the Mac:

```sh
./bootstrap.sh --dry-run
```

The setup doctor reports the state of everything else and never changes the Mac either:

```sh
mise run doctor
```

## The Dock

`dock.txt` owns the Dock: one line per tile, in Dock order from left to right, applications by path and stacks by folder.
A stack line carries the three settings from its Dock context menu, so `display=stack view=fan sort=date-added` reproduces the Downloads stack exactly.

Two tasks move the layout in either direction:

```sh
mise run dock:apply
mise run dock:export
```

`dock:apply` rebuilds the Dock from the file, and `dock:export` captures the running Dock back into it.
Preview an apply without touching the Dock with `mise run dock:apply --dry-run`, which prints the resulting layout tile by tile.
That is the same `--dry-run` convention `./bootstrap.sh` uses.

The Dock is deliberately not a `mise bootstrap` phase, and no hook applies it.
Every other stage converges forward on every run, which is right for a package list and wrong for a Dock, because an icon dragged into place last week is work that a converging phase would silently undo.
Applying the manifest is a decision, so it is a command.

`mise run dock:apply` leaves out an application that is not installed yet and prints what it left out.
A new Mac therefore gets every application it already has, in the right order, rather than a Dock full of question marks.
Running the task again once the remaining casks and Mac App Store applications have arrived puts each one back in its own place, because the position comes from the file and not from the order things were installed.

`mise run doctor` reports when the Dock and `dock.txt` differ.
That report is the reminder to capture a change, and it warns rather than fails, because a Dock that was rearranged an hour ago is not a broken setup.

macOS stores much more per tile than a path: a bookmark that follows an application when it moves, a cached label, and a GUID that means nothing on a second Mac.
None of that is portable, so the manifest keeps the path alone and lets the Dock rebuild the rest on its next restart.
`~` stands for the home directory, so the file carries no account name.

## Managed Applications

Homebrew installs these applications:

- AltTab
- Android Studio
- Aqua Voice
- ChatGPT
- Claude Desktop
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
- Pear Desktop for YouTube Music
- Proton VPN
- Raycast v1
- Spark
- Tailscale
- T3 Code
- TextMate
- Tower
- Visual Studio Code
- Vorssaint
- WezTerm
- WhatsApp

Homebrew also installs Claude Code, the Codex CLI, the Cursor CLI, and Grok Build as casks.

Homebrew installs these command-line tools: Agent Browser, App Store Connect CLI, AXe, BFG, CocoaPods, Fallow, Fastlane, fd, ffmpeg, GitHub CLI, Git LFS, Gitleaks, jq, LazyGit, the Linear CLI, the Maestro CLI, Mole, Oh My Pi, OpenCode, the Resend CLI, ripgrep, the Sentry CLI, the Sentry Wizard, Tmux, Watchman, and YouTube-DLP.

The interactive shell tools Antidote, bat, eza, fd, FZF, ripgrep, Starship, and Zoxide are covered in the shell section below.

The Mac App Store installs Actions, Folder Quick Look, Helm, Obsidian Web Clipper, RocketSim, Timepage, and Xcode.

Apple Developer, TestFlight, Notability, Magnet, Mela, Arc, Slack, Figma, the Affinity suite, GitHub Desktop, Parsec, Proton Pass, KeepingYouAwake, Stats, and Stremio are deliberately excluded. Raycast Window Management replaces Magnet.

Only Hack Nerd Font is installed. The Fira Code, JetBrains Mono, Meslo, and Symbols Only Nerd Fonts are deliberately excluded.

Raycast v1 comes from Homebrew. Raycast v2 Beta is a direct download from [raycast.com/new](https://www.raycast.com/new) because no official Homebrew cask exists.

The setup does not install Rosetta 2. No managed cask declares an Intel requirement, and Minecraft Java Edition has shipped a native Apple Silicon launcher since version 1.19 in June 2022.

Maestro Studio, Recordly, and Raycast v2 Beta have no suitable Homebrew cask or Mac App Store entry and are downloaded by hand in [the setup guide](setup-guide.html).

Sentry Spotlight is excluded as well.

## Managed Runtimes and Global CLIs

mise manages:

- Node.js LTS
- Bun
- pnpm
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
- Gemini Notebook CLI
- Portless
- Prettier
- Pyright
- QMD
- React Doctor
- Turbo
- TypeScript
- TypeScript Language Server
- Vercel CLI

The Gemini Notebook CLI is the one Python-backed entry.
It is installed from PyPI as `notebooklm-mcp-cli` and provides `nlm`, the `notebooklm-mcp` MCP server, and the bundled Gemini Notebook skill.
See [jacob-bd/gemini-notebook-mcp-cli](https://github.com/jacob-bd/gemini-notebook-mcp-cli).

All npm-backed CLIs, including Biome and Prettier, are installed by Bun through mise.

pnpm is available globally for projects that expect it, alongside Bun and the `npm` that ships with Node.js LTS.
mise installs it from the aqua backend as a standalone binary, so it is versioned in `mise.lock` and does not depend on Bun or npm.

The minimum release age configured in `mise.toml` also applies to supported npm package resolution, including transitive npm dependencies.

Python, uv, and Ruff are installed directly by mise.

The global `UV_PYTHON` setting points uv at the Python interpreter selected by the active mise configuration, so a project-level mise version can still override the global Python 3.12 default.

AgentMail CLI, OpenSrc, the Native SDK CLI, the Playwright CLI, Higgsfield CLI, SnapAI, and Firecrawl CLI are intentionally excluded.

Portless is the one entry here that also needs machine state outside mise, and [Local Development URLs](#local-development-urls) documents it.

YouTube-DLP and the new Sentry CLI are installed through Homebrew because they are native command-line tools rather than project runtimes.

YouTube-DLP has no managed configuration in this repository.

Global `npm` and `undici` are not installed as separate tools.

Fastlane is installed through Homebrew for iOS and Android release automation.

XcodeGen is intentionally not installed because React Native does not require it and no managed project currently uses an XcodeGen `project.yml` specification.

## Local Development URLs

[Portless](https://github.com/vercel-labs/portless) replaces development port numbers with stable named URLs.
A dev server started through it is reachable at `https://<app>.dev` instead of `http://localhost:3000`, which removes port collisions, keeps cookies and local storage separate per app, and gives agents a URL they cannot guess wrong.

`mise.toml` owns the two settings that make this global:

| Variable | Value | Effect |
| --- | --- | --- |
| `PORTLESS_TLD` | `dev` | Serves every app under `.dev` instead of the `.localhost` default. |
| `PORTLESS_TAILSCALE` | `1` | Publishes every app to the tailnet through `tailscale serve`. |

`PORTLESS_FUNNEL` stays unset on purpose.
Funnel would expose the same dev server to the public internet, and tailnet sharing is the intended reach.

`/Applications/Tailscale.app/Contents/MacOS` is on `PATH` because the Tailscale cask keeps its CLI inside the app bundle and portless spawns `tailscale` as a child process, where a Zsh alias would not be visible.

Portless upstream recommends `.test` over `.dev`, because `.dev` is a real Google-owned gTLD.
Two consequences follow from that choice.
The HSTS preload on `.dev` forces HTTPS, which costs nothing here because portless already serves HTTPS through its own trusted local certificate authority.
The `/etc/hosts` entries portless writes shadow the matching public domain on this machine, so an app must not be named after a real `.dev` site.

Three steps stay manual, because they need administrator rights or the Tailscale admin console, and [`setup-guide.html`](setup-guide.html) carries them:

```bash
portless trust                       # local certificate authority into the system trust store
portless service install --tld dev   # root launchd service, so port 443 is bound after a reboot
portless service status              # installed port, HTTPS mode, TLDs, and state directory
```

The launchd service stores the TLD in its own configuration, so the proxy comes back on `.dev` after a reboot without a shell that has the mise environment.

Portless is deliberately not a dotfile.
Its state lives in `~/.portless`, which holds a generated certificate authority and its private key, and neither may ever reach this repository.

## Mobile Toolchains

The repository installs the containers for the iOS and Android toolchains and nothing inside them.

Homebrew installs Android Studio, the Mac App Store installs Xcode, and mise installs Zulu JDK 17.
The shell configuration exposes `ANDROID_HOME`, `emulator`, and `platform-tools`, and mise exposes `JAVA_HOME` for Zulu JDK 17 wherever its shell activation is active.

It does not install Android SDK packages, accept Android licenses, create an emulator, install a Simulator runtime, or accept the Xcode license.

Android Studio owns that state and provides the SDK Manager and Device Manager that the official React Native instructions drive.
Pinning SDK versions here would freeze what that guide keeps moving.
Android Studio must use `~/Library/Android/sdk`, which is the path the shell configuration sets.

[React Native currently recommends Zulu JDK 17](https://reactnative.dev/docs/set-up-your-environment?platform=android).

[mise installs that JDK and automatically points `JAVA_HOME` at the active Java installation](https://mise.jdx.dev/lang/java.html), so the separate Homebrew `zulu@17` cask is intentionally unnecessary.

The Xcode and Android Studio phases of [the setup guide](setup-guide.html) walk through the onboarding both applications need.

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

The `dotfiles` alias opens `~/github/phoenix-error/dotfiles`, the fixed clone path this repository requires.

The `cc` alias starts Claude Code in Auto mode, and `ccw` starts it in Auto mode inside a fresh git worktree, which accepts an optional worktree name as in `ccw feature-x`.

Both pass `--permission-mode auto` even though `~/.claude/settings.json` already defaults to Auto mode, so a project that sets a different default mode does not change what the aliases do.

`cc` shadows the C compiler in interactive shells only, because Zsh aliases do not apply to scripts or Makefiles.

The `keykey` command switches to the next enabled macOS keyboard layout and prints the one it landed on, so repeated runs cycle through them.
`keykey --list` shows every enabled layout and marks the active one.

It is an executable in `home/.local/bin` rather than an alias, because a Zsh alias cannot hold a program and `home/.zshrc` already puts `~/.local/bin` on `PATH`.

Layouts themselves stay unmanaged, because the enabled set is a per-machine choice made in System Settings under Keyboard, Text Input, Input Sources.

`keykey` switches the layout through Text Input Services instead of writing `AppleSelectedInputSources` with `defaults`, which only sets the preference and leaves the running system on the previous layout until the input menu agent overwrites the key again.

That API is reachable from Swift and not from the shell, so the command embeds a small Swift program and compiles it into `~/.cache/keykey` on first use.
The cache is keyed by the hash of the command file, so editing the command rebuilds it and no build step has to run during setup.

Zsh plugins are managed only by Antidote through `home/.zsh_plugins.txt`.

Repository agent instructions explicitly prohibit installing individual Zsh plugins through Homebrew, Oh My Zsh, or manual clones.

WezTerm uses Hack Nerd Font, transparency, blur, minimal tabs, and resize-only window decorations.

It spells the Rose Pine Moon palette out instead of selecting a bundled color scheme.
Every bundled Rose Pine Moon variant assigns the ANSI colors differently than the official palette, so WezTerm and Ghostty would not render the same green and blue, and `rose-pine-moon` also sets the selection color to the background color, which makes a selection invisible.
The explicit palette also covers the tab bar, which no bundled scheme carries at all.

Ghostty uses the same Rose Pine Moon theme, Hack Nerd Font, 14-point font size, 0.8 background opacity, and blur level 50.

Its configuration file is named `config` with no extension, because that is the only name Ghostty reads inside `~/.config/ghostty`.

Ghostty keeps its tab bar inside the macOS titlebar, so `macos-titlebar-style` is `tabs`.
The `hidden` style hides the titlebar together with the tab bar, which leaves new tabs open but invisible, and `window-show-tab-bar` cannot compensate because that setting is GTK-only.

Ghostty starts every surface through `/usr/bin/login`, the way Terminal.app does, so a new window or tab would print a `Last login` banner.

Ghostty has no setting for that line, because it comes from `login` itself. The managed empty `~/.hushlogin` silences it for every program that goes through `login`.

Herdr starts from its built-in Rose Pine theme and overrides the supported color tokens with the official Rose Pine Moon palette.

Its panel background is reset so it inherits opacity and blur from the host terminal.

The repository manages only Herdr's onboarding, agent-panel, notification, and theme settings.

## VS Code and Cursor

VS Code is the primary editor.

`EDITOR` and `VISUAL` point at `code --wait`, so Git and other command-line tools open VS Code and wait for the file to close.

Cursor stays installed as a secondary editor and keeps mirroring the shared settings.

Neovim is intentionally not part of this setup.

Homebrew installs both Visual Studio Code and Cursor.

mise symlinks one shared `settings.json` into the native macOS user settings location for both editors.

Both editors use Hack Nerd Font Mono, Rosé Pine Moon, automatic import updates, and the shared editor preferences already present on the current Mac.

Cursor-specific composer and terminal keys live in that same file. VS Code ignores them.

This repository does not manage editor extensions.

VS Code Settings Sync owns the installed VS Code extension set across machines after you sign in and turn sync on.

Cursor has no Microsoft Settings Sync.
When Cursor should mirror the VS Code extension set, spawn a Claude agent with the example prompt in [setup-guide.html](setup-guide.html).
The agent installs every VS Code extension that Cursor can load, skips Marketplace-only IDs such as Modernized, and substitutes `anysphere.cursorpyright` for Pylance.

The shared `settings.json` still owns language-specific formatters: Ruff for Python, Biome for JavaScript, TypeScript, JSON, and JSONC, and Prettier for CSS, SCSS, HTML, GraphQL, Markdown, and YAML.

Project-level `pyproject.toml`, `ruff.toml`, Biome, Prettier, and ESLint configuration take priority over the global editor defaults.

Fallow's CLI stays in `Brewfile`.
Projects that want editor diagnostics should add a matching `fallow` development dependency themselves.

Zed is not installed or configured.

## Agent Configuration

One public `home/AGENTS.md` file is the Shared Core: the one agent-agnostic instruction file every installed agent reads.

mise symlinks it to the canonical shared location and every native path a managed agent actually reads:

- `~/.agents/AGENTS.md` as the canonical vendor-neutral location
- `~/.claude/CLAUDE.md` for Claude Code
- `~/.codex/AGENTS.md` for Codex
- `~/.omp/agent/AGENTS.md` for Oh My Pi
- `~/.config/opencode/AGENTS.md` for OpenCode

This gives the supported agents the same global working rules without maintaining duplicate files.

Tool-specific mechanics stay out of the Shared Core and live in a Tool Layer.

Claude Code reads `home/.claude/rules/*.md`.

Oh My Pi reads the sticky `~/.omp/agent/RULES.md` dotfile, which this repository owns as `home/.omp/agent/RULES.md`.

One small topical file per concern.

Create a new Tool Layer file only when a tool needs behavior beyond the Shared Core.

A file becomes a managed dotfile only when it is pure human-authored declaration and the tool never rewrites it at runtime.

The following paths are Machine State and stay outside this repository:

- `~/.omp/agent/config.yml` because omp rewrites it, and the desired keys converge through `scripts/setup-omp-agent.sh`
- `~/.omp/agent/agents/*.md` because omp provisions those files itself
- `~/.claude.json` because Claude Code rewrites it on every session.
  Workspace trust, project state, and login live there.
  mise never links or converges this file.

- `~/.codex/config.toml` because Codex rewrites trust hashes and plugin state there
- `~/.grok` because the Grok TUI writes that config, and instructions arrive through the Compat Path from `~/.claude/CLAUDE.md`
- `~/.cursor` because Cursor has no global instruction surface, and the Cursor CLI reads project `AGENTS.md` files only
- OpenCode `opencode.json` because this repository does not create one, and the Shared Core symlink is enough
- All auth and credential state

OpenCode is installed as a Homebrew formula and reads the Shared Core through the `~/.config/opencode/AGENTS.md` symlink.

It gets no configuration beyond the Shared Core.

The Cursor CLI has no global instruction surface and is deliberately out of scope.

It reads `AGENTS.md` from a project only, so nothing global is linked for it.

Grok Build is covered through the Compat Path: it reads `~/.claude/CLAUDE.md` and `~/.claude/rules/*.md`.

Do not add a `~/.grok` link, because Grok would then load the Shared Core twice.

If xAI removes that compat reading, Grok loses the Shared Core.

The Claude Code `codex` and `composio` plugins arrive through the managed `home/.claude/settings.json`.

Their runtime plugin state stays untracked.

omp settings converge through `scripts/setup-omp-agent.sh` and `scripts/omp-agent-settings.json`, which a `[bootstrap.hooks.final]` entry calls.

Never symlink or hand-edit `~/.omp/agent/config.yml` from this repository.

There is no advisor role.

| Role | Model |
| --- | --- |
| default | `xai-oauth/grok-4.6:high` |
| slow | `anthropic/claude-fable-5:high` |
| plan | `anthropic/claude-fable-5:high` |
| designer | `anthropic/claude-fable-5:high` |
| task | `xai-oauth/grok-4.6:high` |
| smol | `xai-oauth/grok-4.6:medium` |

Fallback chains:

- `default` falls back to `anthropic/claude-sonnet-5:high`
- `slow`, `plan`, and `designer` fall back to `openai-codex/gpt-5.6-sol`, then `xai-oauth/grok-4.6:xhigh`
- `smol` falls back to `anthropic/claude-sonnet-4-6:medium`
- `task` has no chain entry and inherits the default chain

The Shared Core also names the command-line wrappers that agents must prefer over their built-in tools: `gh-axi` instead of `gh`, `lavish-axi` for visual review surfaces, `chrome-devtools-axi` for driving Chrome, `ctx7` for library documentation, `nlm` for Gemini Notebook, and `composio` for connected third-party apps.

Every one of those tools is installed by this setup, and `home/.claude/settings.json` starts `gh-axi`, `chrome-devtools-axi`, and `lavish-axi` as session-start hooks.

`home/.claude/rules/context7.md` is the only managed Claude rule. It tells agents to use the mise-installed `ctx7` CLI rather than `npx ctx7@latest`, so documentation lookups also respect the pinned version and the minimum release age.

Herdr installs its own agent hooks through `mise run agents:herdr`. This repository never copies a generated hook file, and `~/.claude/hooks` is not a managed dotfile path.

Claude Code also receives the public `settings.json` and Bun-powered status line from this repository.

The `codex` plugin and its `openai-codex` marketplace are enabled through the managed `home/.claude/settings.json`.

Its runtime plugin state stays untracked.

Homebrew installs every coding agent: Claude Code, Codex, the Cursor CLI, and Grok Build as casks, and Oh My Pi and OpenCode as formulae.

The `cursor-cli` cask provides the `cursor-agent` binary, which is the command-line agent and a separate artifact from the `cursor` editor cask.
Herdr hooks that CLI, not the editor, so both casks are declared.

Agent releases ship several times a day, faster than a mise lockfile and a minimum release age can usefully follow, so Homebrew and the daily tool updater keep them current. Anthropic also deprecated the Claude Code npm package in January 2026 with version 2.1.15 in favour of the native binary.

Every Homebrew cask and formula pins the exact release artifact with a SHA-256 checksum, which a vendor install script piped into a shell cannot offer.

The agents' built-in updaters are not relied on: the Homebrew-installed binaries stay at the version Homebrew installed until the next upgrade, and each CLI's `update` subcommand only works for its native install layout.

Oh My Pi comes from `can1357/tap` as the `omp` formula, a native binary at version 17. Its npm package stalled at 0.2.0 and is not the same distribution.

Claude agent teams use Tmux split panes.

Herdr remains the primary multiplexer for persistent agent sessions.

Tmux is installed as a dedicated dependency for Claude's split-pane team display and does not currently have a managed configuration file.

Claude Code starts in Auto mode, which runs tasks without routine permission prompts while retaining Claude's background safety checks.

Auto mode availability depends on the active Claude plan, model, provider, and organization settings.

The Pyright and TypeScript LSP plugins remain enabled so Claude receives diagnostics, type information, definitions, and references while editing supported projects.

Claude authentication, caches, conversation history, local settings, and generated plugin state are not tracked.

The [ChatGPT desktop application](https://learn.chatgpt.com/docs/app) includes the Codex desktop experience, and Homebrew installs the standalone Codex CLI beside it.

Oh My Pi extends the Pi coding agent into a multi-agent orchestration setup, and Herdr installs the matching integrations for Claude Code, Codex, Cursor, Oh My Pi, OpenCode, and the Grok CLI.

The Pi coding agent is not installed.
Oh My Pi ships self-contained and discovers the canonical `~/.agents/skills` store directly, so skill installs need no Pi target.

The setup owns no agent skills.
Skill sources are renamed, split, and retired far faster than the rest of this inventory, and a stale entry would fail the whole run without adding anything a fresh Mac needs to work.
They are installed by hand from the Agents phase of [setup-guide.html](setup-guide.html) instead.

The repository does not copy local plugin caches or private skill folders.

The Claude plugins enabled in `home/.claude/settings.json` ship their own skills, which that file does not govern.

## Homebrew 6 Trust

mise symlinks the root `Brewfile` to Homebrew's global `~/.homebrew/Brewfile`.

Official Homebrew taps require no additional trust.

The AXe CLI, Linear CLI, Maestro CLI, Oh My Pi, Resend CLI, Sentry CLI, Sentry Wizard, Pear Desktop, and FluxMarkdown come from third-party taps.

Each of those packages declares item-scoped `trusted: true` in `Brewfile`, so the repository does not trust the rest of its tap.

Any future third-party formula, cask, or command must follow the same narrow trust policy.

The generated `~/.homebrew/trust.json` file is runtime state and is intentionally ignored.

The existing Mac's trust file is not copied because it contains stale entries for tools that this setup no longer manages, including Oh My Posh and the old Homebrew Bun installation.

## Updating Tool Versions

A launchd agent, installed by `scripts/setup-autoupdate.sh` as a final bootstrap stage, runs `scripts/update-tools.sh` every morning at 07:00 and logs to `~/Library/Logs/dotfiles-update.log`.
It upgrades Homebrew formulae, the casks that cannot update themselves, Mac App Store applications, mise, and the mise-managed tools, and never installs or removes anything the inventories declare or dropped.
It also clears Gatekeeper quarantine from every installed cask app, including the ones Sparkle updated since the previous run, so nested helpers such as Codex Computer Use.app stop asking "Are you sure you want to open it?" after each update.
Casks marked `auto_updates` are left to the applications' own updaters, which the managed macOS defaults switch to silent automatic installs for every Sparkle-based app.

A second launchd agent, installed by `scripts/setup-omp-sync.sh`, runs `scripts/sync-omp-agent-settings.sh` every evening at 20:00 and logs to `~/Library/Logs/dotfiles-omp-sync.log`.
It copies drifted tracked Oh My Pi settings from this Mac into `scripts/omp-agent-settings.json` and never commits.
Review that diff and commit it when the next machine should inherit the change.
`mise run omp:sync` runs the capture now, and `mise run omp:schedule` reinstalls the agent.

A cask whose installer needs sudo, today only BasicTeX, is skipped unattended and upgraded by an interactive `mise run update:tools`.
After a Sparkle update the first-launch dialog can return until the next morning run.
`mise run apps:clear-quarantine` clears it immediately.


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

`mise.lock` is not tracked. Only mise can write it, every entry in `mise.toml` is a fuzzy version, and a committed copy went stale within months without ever having been the source of truth. `mise.toml` is that source, and the minimum release age is what actually limits exposure.

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

That includes `~/.claude/settings.local.json` and `mise.local.toml`.

A setting that would otherwise land in a local override belongs in the managed file, so a new Mac reproduces it. The Claude plugin toggles and the reduced-motion preference were moved into `home/.claude/settings.json` for exactly that reason.

Git is the deliberate exception. `~/.gitconfig`, `~/.ssh/config`, and anything under `~/.config/git/` are not managed at all, so they need no override layer. See [Declarative Ownership](#declarative-ownership).

The matching `.gitignore` entries stay as a safety net against accidental commits, not as an invitation to create such files.

