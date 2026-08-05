# Repository Instructions

## Purpose

This is a public, Apple Silicon macOS setup repository.

The repository must remain safe to clone and inspect without exposing credentials or machine-specific state.

Do not apply the real setup to the current Mac unless the user explicitly changes that instruction.

## Configuration Ownership

- `Brewfile` owns the exact desired top-level Homebrew formulae, casks, taps, and fonts.
- `Brewfile.mas` owns Mac App Store applications.
- `mise.toml` owns runtimes, global npm-backed CLIs, setup tasks, dotfile mappings, and scalar macOS defaults.
- `mise.lock` owns resolved mise tool versions. Only mise writes it, it stays local to each machine, and it must never be tracked.
- `home/.zsh_plugins.txt` owns every Zsh plugin.
- `docs/agent-skills.md` documents how global agent skills are installed by hand and which sources to skip.
- `home/.config/editors/settings.json` owns the shared VS Code and Cursor user settings.
- `home/` owns public dotfiles that mise links into the home directory.
- `home/.claude/rules/` owns the Claude rules that this setup supports.
- `bootstrap.sh` owns bare-metal initialization only: Xcode Command Line Tools, Homebrew, mise, `mise trust`, and linking `~/.zprofile`, `~/.zshrc`, and `~/.zsh_plugins.txt` so both tools are reachable as ordinary commands. It stops there and installs no declared package.
- `scripts/setup.sh` owns every managed setup stage and the required stage order. The `setup` task in `mise.toml` is its only caller.
- `scripts/lib.sh` owns the shared logging, dry-run, and manual-gate helpers. Source it, do not execute it.
- `scripts/` owns idempotent setup behavior that cannot be expressed safely as scalar mise configuration.

New setup behavior belongs in `scripts/setup.sh` or in a `scripts/` helper that it calls.

Only add a stage to `bootstrap.sh` when it must run before mise exists. Everything else is a managed stage.

Do not add a third setup entry point.

## Package Manager Ownership

Every tool has exactly one installation channel. Decide it with this rule, in order:

1. A graphical application belongs in `Brewfile` as a cask, or in `Brewfile.mas` when the Mac App Store is its only channel.
2. A language runtime belongs in `mise.toml`. That covers Node, Bun, Python, Java, uv, and Ruff.
3. A coding agent belongs in `Brewfile` whenever Homebrew ships it. Agent binaries update themselves at runtime, so a mise lockfile cannot hold their version and the seven-day minimum release age buys nothing.
4. Anything else that is installed through a language runtime belongs in `mise.toml` with its backend prefix, so `npm:` or `pipx:`. mise resolves it into the local `mise.lock` and enforces the seven-day minimum release age, which Homebrew cannot do.
5. Everything else is a native binary and belongs in `Brewfile` as a formula.

A tool that ships both a native binary and a runtime package follows rule 4 unless its vendor deprecated the runtime package, in which case it follows rule 5.

Never declare the same tool in both `Brewfile` and `mise.toml`.

mise itself is the one exception to the rule and belongs in neither inventory.
`bootstrap.sh` installs it from `https://mise.run` into `~/.local/bin/mise`, which is the method the mise documentation recommends for macOS.
It has to exist before `Brewfile` is applied, and `brew bundle cleanup` would otherwise uninstall the binary that is running the setup.
Do not add `brew "mise"` back.

Do not switch to the `https://mise.run/zsh` installer variant. It appends the activation line to `~/.zshrc`, which is a managed symlink here, and `mise bootstrap dotfiles apply` refuses that conflict rather than replacing the file.

Never pass `--force` to `mise bootstrap dotfiles apply`. Refusing a conflict is the behavior that protects a hand-written dotfile.

Before adding a tool, check the other inventory for an existing entry.

The rule covers declarations, not dependency closures. Homebrew formulae pull their own runtimes, so `agent-browser` and `pi-coding-agent` bring `node`, and `watchman` and `yt-dlp` bring `python`. Those installs are unavoidable and are not duplicate declarations.

`home/.zshrc` puts `~/.local/bin` on `PATH` after Homebrew's shell environment and activates mise after that, so mise is findable at its install path and its shims still come first on `PATH`, which makes the declared runtime versions win. Do not reorder those three blocks.

`~/.local/bin` is the only `PATH` entry `home/.zshrc` sets. Everything else, including `ANDROID_HOME` and the Android SDK directories, belongs in `[env]` in `mise.toml`. Do not duplicate a managed environment variable into the shell configuration.

Every tool lookup in `home/.zshrc` stays guarded. `bootstrap.sh` links that file before the `Brewfile` is applied, so the first terminal after initialization has none of the declared tools yet, and an unguarded call would error there.

## Editor Extension Policy

This repository does not manage editor extensions.

VS Code Settings Sync owns the installed VS Code extension set across machines.

Cursor has no Microsoft Settings Sync. When Cursor should mirror VS Code, spawn a Claude agent with the example prompt in `docs/setup-guide.html` and install only extensions that Cursor can actually load.

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

Cursor is the primary editor and owns `EDITOR` and `VISUAL`.

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

`docs/agent-skills.md` documents install commands and excluded sources. Keep it accurate when the install flow or policy changes.

Do not add a skill source without an explicit decision from the user.

Document BunX, not `npx`, manually copied skill directories, or plugin-cache contents.

The four agent targets are Claude Code, Codex, Cursor, and Pi. Oh My Pi extends Pi and reads Pi's skill directory, so it needs no separate target.

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

Git and SSH are the exception to the one-managed-file rule. `~/.gitconfig`, `~/.config/git/ignore`, and `~/.ssh/config` are configured by hand and are deliberately not part of this repository. Do not reintroduce them as managed dotfiles.

Settings that would otherwise land in a local override belong in the managed file so a new Mac reproduces them.

The `.gitignore` entries for these paths stay as a safety net against accidental commits, not as an invitation to use them.

## Secrets

Never commit credentials, tokens, private keys, login state, shell history, application databases, or machine identifiers.

Infisical is the managed backend for project and environment secrets.

Use `infisical run -- <command>` to inject secrets only into the process that needs them.

Do not export Infisical secrets globally from `.zshrc` or persist them in generated `.env` files.

Keep SSH private keys and native CLI login state in their own macOS Keychain or application-managed storage.

Never commit Infisical tokens, project identifiers that should remain private, exported secrets, or machine identity credentials.

## Verification

This repository has no test suite. Do not add one.

Verify a change with `./bootstrap.sh --dry-run`, `./scripts/setup.sh --dry-run`, and `./scripts/doctor.sh`, all of which are read-only.

Do not install, upgrade, uninstall, clean up, or apply macOS settings on the current Mac while preparing this repository.
