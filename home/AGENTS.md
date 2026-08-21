# Lucas's Global Agent Instructions

These instructions apply to Lucas's agents across projects.

## General Guidelines

- Never use the em dash character.
- Use a plain hyphen instead.
- Never add an agent name as a commit co-author.
- Never manually modify `CHANGELOG.md` files or files marked as generated.
- When writing or substantially editing long Markdown files, put each full sentence on its own physical line.
- Prefer quality, simplicity, robustness, scalability, and long-term maintainability over development cost.
- Start bug fixes by reproducing the problem as closely as practical to the end-user experience.
- Be exacting about user interfaces, accessibility, visual quality, lint failures, test failures, and test flakiness.
- Preserve unrelated user changes and do not hide existing failures.
- Never commit credentials, tokens, private keys, authentication state, or machine-specific secrets.

## Instruction Layering

- This file is the shared core that every installed agent reads, and it stays agent-agnostic.
- Project-level instruction files override this file on conflict.
- This file holds only machine-invariant preferences; anything repo-specific belongs in the project's own instruction files.
- Tool-specific mechanics live in each tool's own layer, such as `~/.claude/rules/` for Claude Code and `~/.omp/agent/RULES.md` for Oh My Pi.
  Never add tool-specific mechanics to this file.

## Preferred Command-Line Tools

These wrappers replace the tools an agent would otherwise reach for by default.
Use them without being asked, and fall back to the underlying tool only when the wrapper cannot express the task.

- Use `gh-axi` for every GitHub operation instead of `gh` or the GitHub API.
- Use `lavish-axi` whenever a response is easier to grasp as a rich page than as prose: plans, comparisons, diagrams, tables, reports, and review surfaces.
- Use `chrome-devtools-axi` to drive or inspect a Chrome session instead of any other browser automation tool.
- Use `ctx7` for library documentation instead of web search.
- Use `nlm` for Gemini Notebook work.
- Use `composio` to search, connect, and run actions in connected third-party apps that have no dedicated wrapper here.

## Optional Personal Context

When a task would benefit from Lucas's personal viewpoints, read `~/OPINIONS.md` if it exists.

When writing or posting in Lucas's voice, read `~/VOICE.md` if it exists.

## Picking the right models for workflows and subagents

Price is what I actually pay under my current subscriptions, and it is the one column where higher = more expensive.
Speed, intelligence, and taste rank higher = better.
Intelligence is how hard a problem you can hand the model unsupervised.
Taste covers UI/UX, code quality, API design, and copy.

| model    | price | speed | intelligence | taste |
| -------- | ----- | ----- | ------------ | ----- |
| gpt-5.6  | 5     | 5     | 9            | 6     |
| sonnet-5 | 6     | 8     | 5            | 6     |
| opus-5   | 7     | 6     | 7            | 8     |
| fable-5  | 9     | 3     | 9            | 10    |
| grok-4.6 | 2     | 9     | 7            | 6     |
| glm-5.3  | 1     | 6     | 6            | 4     |

claude-sonnet-4-6 is not ranked; it exists in this setup only for tiny background tasks and as their fallback.

How to apply:

- These are defaults, not limits.
  You have standing permission to override them: if a cheaper model's output does not meet the bar, redo the work with a smarter model without asking.
  Judge the output, not the price tag.
- When axes conflict for anything that ships: intelligence > taste > speed > price.
- Speed only outranks intelligence when I am waiting on the result interactively.
  For background, batched, or subagent work, ignore speed entirely.
- Bulk and mechanical work (clear-spec implementation, migrations, searches, data collection): grok-4.6 first, sonnet-5 as the alternative, occasionally opus-5.
- Use gpt-5.6 sparingly, because my ChatGPT subscription is small.
  Its niche is an independent second opinion on plans and reviews, and a cross-provider fallback.
- glm-5.3 is the cheapest and the weakest model; it is bound to no role.
  Never review with glm-5.3.
- Anything user-facing (UI, copy, API design) needs taste >= 7 - that is opus-5 or fable-5 only, regardless of how mechanical the task looks.
- Thinking levels: cheap models (grok-4.6, sonnet-5, glm-5.3) never run below medium, and implementation work on grok-4.6 or sonnet-5 runs on high.
- Reviews of plans and implementations: fable-5 or opus-5, optionally gpt-5.6 as an extra independent perspective.
- Never use Haiku.
- Orchestrator discipline: an expensive main model (fable-5, opus-5) spends its tokens on judgement - talking to me, decomposing, dispatching, and reviewing.
  Grunt work goes to subagents on the cheap models.
  The expensive model edits files directly only when the change itself is judgement-bound: API design, tricky refactors, user-facing copy.

## Which agent for what

- Oh My Pi is the primary agent.
  It reaches every model in the table directly, so work that wants a non-Claude model or mixed-model orchestration belongs there.
- Claude Code is the fallback for Claude-only work.
  Inside Claude Code, gpt-5.6 is reachable through the Codex CLI via the `codex` plugin: the `codex-cli-runtime` and `codex-result-handling` skills and the `/review` and `/adversarial-review` commands.
- Codex, OpenCode, and Grok Build are secondary agents; they read this file and need no extra mechanics.
  The Cursor CLI reads instructions per project only.

## Sentry

- Use the `sentry` CLI for Sentry issues, events, projects, releases, traces, logs, and authenticated API work.
- Prefer dedicated `sentry` subcommands before falling back to raw `sentry api` calls.
- Never expose or commit Sentry tokens, DSNs, project credentials, or CLI authentication state.
