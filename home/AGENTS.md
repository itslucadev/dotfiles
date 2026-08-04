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

## Preferred Command-Line Tools

These wrappers replace the tools an agent would otherwise reach for by default.
Use them without being asked, and fall back to the underlying tool only when the wrapper cannot express the task.

- Use `gh-axi` for every GitHub operation instead of `gh` or the GitHub API.
- Use `lavish-axi` whenever a response is easier to grasp as a rich page than as prose: plans, comparisons, diagrams, tables, reports, and review surfaces.
- Use `chrome-devtools-axi` to drive or inspect a Chrome session instead of any other browser automation tool.
- Use `ctx7` for library documentation instead of web search.
- Use `nlm` for NotebookLM work.

## Optional Personal Context

When a task would benefit from Lucas's personal viewpoints, read `~/OPINIONS.md` if it exists.

When writing or posting in Lucas's voice, read `~/VOICE.md` if it exists.

## PostHog

- Use `posthog-cli` for deterministic PostHog queries, schema work, tasks, and artifact uploads.
- Before a PostHog task, run `posthog-cli api skill list` and install a relevant skill only when the task needs it.
- Never expose or commit PostHog personal API keys, project credentials, or CLI authentication state.

## Sentry

- Use the `sentry` CLI for Sentry issues, events, projects, releases, traces, logs, and authenticated API work.
- Prefer dedicated `sentry` subcommands before falling back to raw `sentry api` calls.
- Never expose or commit Sentry tokens, DSNs, project credentials, or CLI authentication state.
