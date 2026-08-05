# Global Agent Skills

This repository does not install agent skills.

The setup owns everything that a fresh Mac needs in order to work: Homebrew, mise, dotfiles, macOS defaults, and the GitHub key.
Skills are a personal, fast-moving choice, so they stay out of `bootstrap.sh` and are installed by hand.

This file documents how to install them, which sources to skip, and how to verify the result.
It is documentation, not an inventory that a script reads.

## Install

Use BunX, never `npx`:

```sh
bunx skills add <owner/repo> --agent <agent> ... --global
```

The four agent targets are `claude-code`, `codex`, `cursor`, and `pi`.
Oh My Pi extends the Pi agent and reads Pi's skill directory, so it needs no separate target.

Install from [mattpocock/skills](https://github.com/mattpocock/skills) with the interactive TUI and pick the skills you want:

```sh
bunx skills add mattpocock/skills \
  --agent claude-code --agent codex --agent cursor --agent pi \
  --global
```

Add `--yes` and one or more `--skill <name>` flags when you want a non-interactive install of a specific subset.

## Gemini Notebook

[Gemini Notebook MCP CLI](https://github.com/jacob-bd/gemini-notebook-mcp-cli) (formerly Google NotebookLM) ships as the PyPI package `notebooklm-mcp-cli`.
This setup installs it through mise as `pipx:notebooklm-mcp-cli`, which provides `nlm` and `notebooklm-mcp`.

Authenticate once:

```sh
nlm login
```

Register the MCP server with each agent that should reach Gemini Notebook:

```sh
nlm setup add claude-code
nlm setup add cursor
nlm setup add codex
```

Install the bundled expert skill for the same agents:

```sh
nlm skill install claude-code
nlm skill install cursor
nlm skill install codex
```

Pi is not supported by `nlm setup` or `nlm skill install`.

Run `nlm doctor` to verify installation, authentication, and agent configuration.

## Skills that arrive another way

The Claude plugins enabled in `home/.claude/settings.json` ship their own skills, and this file does not govern them.

Three names currently arrive through more than one channel, with different behaviour behind each:

- `code-review` may be installed as a skill and also ships in the `code-review` plugin.
- Library documentation is covered by the managed `ctx7` rule and by the `context7` plugin.
- Browser control is covered by the `chrome-devtools-axi` rule, the `chrome-devtools-mcp` plugin, and the `agent-browser` formula.

## Verifying

The Skills CLI keeps one central store at `~/.agents/skills` and links each agent directory into it.

```sh
ls ~/.agents/skills
ls ~/.claude/skills
```

A missing entry in the store means the skill was never installed.
A missing agent link means the skill is present but that agent cannot see it.
