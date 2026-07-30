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
