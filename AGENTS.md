# Repository Instructions

## Purpose

This is a public, Apple Silicon macOS setup repository.

The repository must remain safe to clone and inspect without exposing credentials or machine-specific state.

Do not apply the real setup to the current Mac unless the user explicitly changes that instruction.

## Configuration Ownership

- `Brewfile` owns the exact desired top-level Homebrew formulae, casks, taps, and fonts.
- `Brewfile.mas` owns Mac App Store applications.
- `dock.txt` owns the Dock layout, one line per tile in Dock order. `scripts/sync-dock.sh` is its only reader and its only writer, through `mise run dock:apply` and `mise run dock:export`.
- `mise.toml` owns runtimes, global npm-backed CLIs, setup tasks, dotfile mappings, and scalar macOS defaults.
- `mise.lock` owns resolved mise tool versions. Only mise writes it, it stays local to each machine, and it must never be tracked.
- `home/.zsh_plugins.txt` owns every Zsh plugin.
- `setup-guide.html` owns every manual step on a new Mac, including how the global agent skills are installed by hand and which sources arrive another way.
- `home/.config/editors/settings.json` owns the shared VS Code and Cursor user settings.
- `home/` owns public dotfiles that mise links into the home directory.
- `home/.local/bin/` owns personal commands that are too large to express as a Zsh alias. `home/.zshrc` already puts `~/.local/bin` on `PATH`, so an executable linked there needs no alias, works in every shell, and keeps `home/.zshrc` free of program logic.
- `home/.claude/rules/` owns the Claude rules that this setup supports.
- `bootstrap.sh` owns bare-metal initialization only: Xcode Command Line Tools, Homebrew, mise, `mise trust`, and linking `~/.zprofile`, `~/.zshrc`, and `~/.zsh_plugins.txt` so both tools are reachable as ordinary commands. It stops there and installs no declared package.
- `mise bootstrap` owns the stage order of the managed setup. The `[bootstrap.hooks]` entries in `mise.toml` own the stages that are not one of its native phases, and the `setup` task is the documented entry point.
- `scripts/setup-mise.sh` is the committed copy of the `https://mise.run` installer. Never edit it by hand. Refresh it with `mise run update:mise-installer` and review the diff, which is a checksum and version bump.
- `scripts/lib.sh` owns the shared logging, dry-run, and manual-gate helpers. Source it, do not execute it.
- `scripts/` owns idempotent setup behavior that cannot be expressed safely as scalar mise configuration.

New setup behavior belongs in a `mise bootstrap` phase when mise can express it, and otherwise in a `scripts/` helper that a `[bootstrap.hooks]` entry calls.

Homebrew stays in `Brewfile` and never moves into `[bootstrap.packages]`. mise converges forward only, so that move would silently drop the `brew bundle cleanup` pass that removes undeclared formulae, casks, and taps.

Only add a stage to `bootstrap.sh` when it must run before mise exists. Everything else is a managed stage.

Do not add a third setup entry point.

`bootstrap.sh` runs as the ordinary user and refuses to start as root, because the Homebrew installer refuses a root run and everything after it writes into the user's home directory.

Homebrew is the only stage that needs administrator rights, and it gets them from a single `sudo -v` before its installer runs.

Do not add `sudo` to another stage, do not remove the root guard, and do not make `--dry-run` ask for a password.

## Package Manager Ownership

Every tool has exactly one installation channel. Decide it with this rule, in order:

1. A graphical application belongs in `Brewfile` as a cask, or in `Brewfile.mas` when the Mac App Store is its only channel.
2. A language runtime belongs in `mise.toml`. That covers Node, Bun, Python, Java, uv, and Ruff.
3. A coding agent belongs in `Brewfile` whenever Homebrew ships it. Agents release too often for a lockfile and a minimum release age to usefully follow, and the daily tool updater keeps them current.
4. Anything else that is installed through a language runtime belongs in `mise.toml` with its backend prefix, so `npm:` or `pipx:`. mise resolves it into the local `mise.lock` and enforces the minimum release age configured in `mise.toml`, which Homebrew cannot do.
5. Everything else is a native binary and belongs in `Brewfile` as a formula.

A tool that ships both a native binary and a runtime package follows rule 4 unless its vendor deprecated the runtime package, in which case it follows rule 5.

Never declare the same tool in both `Brewfile` and `mise.toml`.

mise itself is the one exception to the rule and belongs in neither inventory.
`bootstrap.sh` installs it into `~/.local/bin/mise` with the committed `https://mise.run` installer in `scripts/setup-mise.sh`, which is the method the mise documentation recommends for macOS.
It has to exist before `Brewfile` is applied, and `brew bundle cleanup` would otherwise uninstall the binary that is running the setup.
Do not add `brew "mise"` back.

Do not switch to the `https://mise.run/zsh` installer variant. It appends the activation line to `~/.zshrc`, which is a managed symlink here, and `mise bootstrap dotfiles apply` refuses that conflict rather than replacing the file.

Never pass `--force` to `mise bootstrap dotfiles apply`. Refusing a conflict is the behavior that protects a hand-written dotfile.

Before adding a tool, check the other inventory for an existing entry.

The rule covers declarations, not dependency closures. Homebrew formulae pull their own runtimes, so `agent-browser` and `opencode` bring `node`, and `watchman` and `yt-dlp` bring `python`. Those installs are unavoidable and are not duplicate declarations.

`home/.zshrc` puts `~/.local/bin` on `PATH` after Homebrew's shell environment and activates mise after that, so mise is findable at its install path and its shims still come first on `PATH`, which makes the declared runtime versions win. Do not reorder those three blocks.

`~/.local/bin` is the only `PATH` entry `home/.zshrc` sets. Everything else, including `ANDROID_HOME` and the Android SDK directories, belongs in `[env]` in `mise.toml`. Do not duplicate a managed environment variable into the shell configuration.

Every tool lookup in `home/.zshrc` stays guarded. `bootstrap.sh` links that file before the `Brewfile` is applied, so the first terminal after initialization has none of the declared tools yet, and an unguarded call would error there.

## Dock Policy

The Dock is the one managed thing that no `mise bootstrap` phase and no hook applies.

A Dock is rearranged by hand between two setups, and a converging phase would replace that arrangement with the last captured manifest on every `mise run setup`.

Keep both directions as explicit tasks.

Do not add `dock:apply` to `[bootstrap.hooks]`, to the `setup` task, or to a scheduled job.

`mise run dock:apply` leaves out an application that is not installed and reports it, so a Mac in the middle of its setup gets a correct partial Dock and the next run fills in the rest.

Do not make a missing application fail the task.

`scripts/doctor.sh` reports drift between the running Dock and `dock.txt`, and that report is what replaces an automatic capture.

Keep it a warning, because a Dock that was rearranged an hour ago is not a broken setup.

`mise run dock:export` refuses to write a manifest from a Dock that reports no applications, which is the one way the task could destroy the captured layout.

The manifest holds paths, and for a stack the three settings from its context menu.

Do not add the bookmark blob, the cached label, or the GUID that macOS keeps per tile. None of them is portable to a second Mac, and the Dock rebuilds all three from the path.

## Editor Extension Policy

This repository does not manage editor extensions.

VS Code Settings Sync owns the installed VS Code extension set across machines.

Cursor has no Microsoft Settings Sync. When Cursor should mirror VS Code, spawn a Claude agent with the example prompt in `setup-guide.html` and install only extensions that Cursor can actually load.

Do not add `vscode` entries to `Brewfile`.

Do not reintroduce extension inventories, an installer script, or a mise task for extensions.

Keep formatter defaults language-specific so one tool does not take over unrelated languages.

Prefer project-local formatter and linter configuration over global editor-specific rules.

## Homebrew Trust Policy

Declare Homebrew 6 trust only in `Brewfile` with the narrowest possible `trusted` option.

Prefer trusting one formula, cask, or command over an entire third-party tap.

Do not commit or manage the generated `~/.homebrew/trust.json` file.

Do not add a third-party trust unless the matching package is also part of the managed setup.

## Homebrew Reconciliation Policy

After applying `Brewfile`, reconcile Homebrew formulae, casks, and taps with `brew bundle cleanup --force`.

Restrict that cleanup to formulae, casks, and taps so it does not manage Mac App Store applications, editor extensions, or other package ecosystems.

Do not pass `--zap` because uninstalling an unmanaged cask must preserve its application data and shared support files.

Keep only directly desired formulae and casks in `Brewfile`.

Do not add transitive formula dependencies merely to protect them from cleanup because Homebrew Bundle preserves recursive dependencies and formula dependencies required by managed casks.

Fully qualified formulae and casks implicitly preserve the taps that provide them.

## Zsh Plugin Policy

Antidote is the only Zsh plugin manager.

Homebrew may install the `antidote` formula itself, but it must not install individual Zsh plugins.

Add, update, or remove Zsh plugins only through `home/.zsh_plugins.txt`.

Do not add Oh My Zsh as a framework.

Do not clone plugins manually from `.zshrc`, bootstrap scripts, or setup scripts.

Preserve the deliberate plugin ordering:

1. Completion paths are added before completion initialization.
2. `ez-compinit` initializes completion.
3. FZF Tab loads before plugins that wrap interactive widgets.
4. Zsh Syntax Highlighting loads near the end.
5. History Substring Search loads after Zsh Syntax Highlighting.

If a plugin needs a native CLI dependency, the CLI may belong in `Brewfile`, but the Zsh plugin still belongs in `home/.zsh_plugins.txt`.

## Editor Policy

VS Code is the primary editor and owns `EDITOR` and `VISUAL`.
Cursor stays installed as a secondary editor and keeps mirroring the shared settings.

Neovim is intentionally not part of this setup.

Do not reintroduce `neovim`, an `~/.config/nvim` dotfile entry, or a Neovim plugin manager.

## Terminal Multiplexer Policy

Herdr is the primary terminal and agent multiplexer.

Tmux is installed only to provide Claude agent teams with split panes.

Keep Claude agent teams in Tmux display mode.

Do not add a managed `~/.tmux.conf` unless the user explicitly requests Tmux customization.

## Agent Skill Policy

This repository does not install agent skills, and no script may start doing so.

Skill sources move faster than the rest of the inventory, so the user installs them by hand.

The Agents phase of `setup-guide.html` documents install commands and the sources that arrive another way. Keep it accurate when the install flow or policy changes.

Do not add a skill source without an explicit decision from the user.

Document BunX, not `npx`, manually copied skill directories, or plugin-cache contents.

The four agent targets are Claude Code, Codex, Cursor, and OpenCode. Every install also lands as the canonical copy in `~/.agents/skills`, which Oh My Pi reads natively, so it needs no separate target. Symlinks into that store are the CLI's default install mode; do not pass `--copy`.

Do not add Codex, OpenCode, Ponytail, Understand Anything, or Karpathy skill sources.

## Agent Command-Line Tool Policy

`home/AGENTS.md` declares the wrappers that agents must prefer over their default tools.

Every wrapper named there must be installed by `Brewfile` or `mise.toml`, and every Claude hook in `home/.claude/settings.json` must call a tool that the setup installs.

Do not reference a tool in agent instructions or hooks that a new Mac would not have.

## Claude Rule Policy

`home/.claude/rules/` holds only rules that this setup actually supports.

Currently that is `context7.md`, and its `ctx7` CLI is installed by `mise.toml`.

Do not add a rule for a tool that is not part of the managed setup.

## Herdr Integration Policy

Herdr owns its own agent hooks.

`scripts/install-herdr-integrations.sh` calls `herdr integration install`, and that is the only way hooks reach `~/.claude/hooks` and the other agent directories.

Do not copy a generated `herdr-agent-state` hook into `home/`, and do not manage `~/.claude/hooks` through `mise.toml`.

## No Local Override Files

This setup uses exactly one managed file per tool.

Do not create, document, or read `*.local` override files. That includes `~/.claude/settings.local.json` and `mise.local.toml`.

Git and SSH are the exception to the one-managed-file rule. `~/.gitconfig`, `~/.ssh/config`, and anything under `~/.config/git/` are configured by hand and are deliberately not part of this repository. Do not reintroduce them as managed dotfiles.

Settings that would otherwise land in a local override belong in the managed file so a new Mac reproduces them.

The `.gitignore` entries for these paths stay as a safety net against accidental commits, not as an invitation to use them.

## Secrets

Never commit credentials, tokens, private keys, login state, shell history, application databases, or machine identifiers.

This repository prescribes no secrets backend. Do not introduce one without deciding that question first.

Do not export secrets globally from `.zshrc` or persist them in generated `.env` files.

Keep SSH private keys and native CLI login state in their own macOS Keychain or application-managed storage.

Never commit exported secrets, project identifiers that should remain private, or machine identity credentials.

## Verification

This repository has no test suite. Do not add one.

Verify a change with `./bootstrap.sh --dry-run` and `./scripts/doctor.sh`, both of which are read-only.

Do not install, upgrade, uninstall, clean up, or apply macOS settings on the current Mac while preparing this repository.
