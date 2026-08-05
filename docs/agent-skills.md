# Global Agent Skills

This repository does not install agent skills.

The setup owns everything that a fresh Mac needs in order to work: Homebrew, mise, dotfiles, editor extensions, macOS defaults, and the GitHub key.
Skills are a personal, fast-moving choice, so they stay out of `bootstrap.sh` and are installed by hand from the list below.

This file is the record of which skills belong on the machine.
It is documentation, not an inventory that a script reads.

## Source

Every skill below comes from [mattpocock/skills](https://github.com/mattpocock/skills), except the NotebookLM skill, which ships inside the NotebookLM CLI package.

Use BunX with a pinned Skills CLI version, never `npx`:

```sh
bunx --bun skills@1.5.21 add <source-url> --global --yes --skill <name> --agent <agent>
```

The four agent targets are `claude-code`, `codex`, `cursor`, and `pi`.
Oh My Pi extends the Pi agent and reads Pi's skill directory, so it needs no separate target.

## Engineering

Source: `https://github.com/mattpocock/skills/tree/main/skills/engineering`

| Skill | Purpose |
| --- | --- |
| `ask-matt` | Router that picks the right skill for a situation |
| `code-review` | Reviews changes since a fixed point along standards and spec |
| `codebase-design` | Vocabulary for designing deep modules |
| `diagnosing-bugs` | Diagnosis loop for hard bugs and performance regressions |
| `domain-modeling` | Builds and sharpens a project's domain model |
| `grill-with-docs` | Interview that sharpens a plan and writes ADRs along the way |
| `implement` | Implements work from a spec or a set of tickets |
| `improve-codebase-architecture` | Scans for deepening opportunities and reports them |
| `prototype` | Builds a throwaway prototype to answer a design question |
| `research` | Investigates a question against primary sources |
| `resolving-merge-conflicts` | Resolves an in-progress merge or rebase conflict |
| `tdd` | Test-driven development loop |
| `to-spec` | Turns the conversation into a published spec |
| `to-tickets` | Breaks a plan into tracer-bullet tickets |
| `triage` | Moves issues and external PRs through triage roles |
| `wayfinder` | Maps work too large for one agent session |

```sh
bunx --bun skills@1.5.21 add \
  https://github.com/mattpocock/skills/tree/main/skills/engineering \
  --global --yes \
  --skill ask-matt --skill code-review --skill codebase-design \
  --skill diagnosing-bugs --skill domain-modeling --skill grill-with-docs \
  --skill implement --skill improve-codebase-architecture --skill prototype \
  --skill research --skill resolving-merge-conflicts --skill tdd \
  --skill to-spec --skill to-tickets --skill triage --skill wayfinder \
  --agent claude-code --agent codex --agent cursor --agent pi
```

`setup-matt-pocock-skills` and `wizard` are deliberately left out.

## Productivity

Source: `https://github.com/mattpocock/skills/tree/main/skills/productivity`

| Skill | Purpose |
| --- | --- |
| `grill-me` | Interview that sharpens a plan or design |
| `grilling` | Stress-tests a plan, decision, or idea |
| `handoff` | Compacts a conversation into a handoff document |
| `teach` | Teaches a skill or concept inside the workspace |
| `writing-for-agents` | Writing skills, AGENTS.md, and CLAUDE.md |

```sh
bunx --bun skills@1.5.21 add \
  https://github.com/mattpocock/skills/tree/main/skills/productivity \
  --global --yes \
  --skill grill-me --skill grilling --skill handoff --skill teach \
  --skill writing-for-agents \
  --agent claude-code --agent codex --agent cursor --agent pi
```

`writing-for-agents` replaced `writing-great-skills` upstream.
An older inventory in this repository still named the retired skill, which no longer exists in the source repository.

`to-questionnaire` and `wait-what` are deliberately left out.

## Misc

Source: `https://github.com/mattpocock/skills/tree/main/skills/misc`

| Skill | Purpose |
| --- | --- |
| `git-guardrails-claude-code` | Hooks that block destructive git commands |
| `scaffold-exercises` | Creates exercise directory structures |
| `setup-pre-commit` | Sets up Husky, lint-staged, type checks, and tests |

```sh
bunx --bun skills@1.5.21 add \
  https://github.com/mattpocock/skills/tree/main/skills/misc \
  --global --yes \
  --skill git-guardrails-claude-code --skill scaffold-exercises \
  --skill setup-pre-commit \
  --agent claude-code --agent codex --agent cursor --agent pi
```

`migrate-to-shoehorn` is deliberately left out.

## NotebookLM

The NotebookLM skill ships inside the NotebookLM CLI package rather than a Git tree, so its own CLI installs it:

```sh
nlm skill install claude-code --level user
nlm skill install cursor --level user
nlm skill install codex --level user
```

## Excluded sources

Matt Pocock's `skills/personal` folder is excluded because `obsidian-vault` points at a Windows vault path and `edit-article` encodes someone else's publishing workflow.
His `deprecated` and `in-progress` folders are excluded as well.

Vercel, Anthropic, Sentry, Expo, Argent, React Doctor, and animation skill sources are excluded.
Ponytail, Understand Anything, Karpathy skills, Codex skills, and OpenCode skills are excluded.

## Skills that arrive another way

The Claude plugins enabled in `home/.claude/settings.json` ship their own skills, and this file does not govern them.

Three names currently arrive through more than one channel, with different behaviour behind each:

- `code-review` exists both in this list and in the `code-review` plugin.
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
