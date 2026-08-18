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
- Use `nlm` for Gemini Notebook work.

## Optional Personal Context

When a task would benefit from Lucas's personal viewpoints, read `~/OPINIONS.md` if it exists.

When writing or posting in Lucas's voice, read `~/VOICE.md` if it exists.

## Picking the right models for workflows and subagents

Rankings, higher = better. Cost reflects what I actually pay (OpenAI has really generous limits), not list price. Intelligence is how hard a problem you can hand the model unsupervised. Taste covers UI/UX, code quality, API design, and copy.

| model    | cost | speed | intelligence | taste |
| -------- | ---- | ----- | ------------ | ----- |
| gpt-5.6  | 7    | 5     | 9            | 6     |
| sonnet-5 | 3    | 8     | 5            | 6     |
| opus-5   | 6    | 6     | 7            | 8     |
| fable-5  | 9    | 3     | 9            | 10    |
| grok-4.6 | 2    | 9     | 7            | 6     |
| glm-5.3  | 1    | 6     | 6            | 4     |

How to apply:

- These are defaults, not limits. You have standing permission to override them: if a cheaper
  model's output doesn't meet the bar, rerun or redo the work with a smarter model without
  asking. Judge the output, not the price tag. Escalating costs less than shipping mediocre work.
- Cost and speed are tie-breakers only; when axes conflict for anything that ships,
  intelligence > taste > speed > cost.
- Speed only outranks intelligence when I'm waiting on the result interactively. For background,
  batched, or subagent work, ignore speed entirely and pick on intelligence.
- Bulk/mechanical work (clear-spec implementation, data analysis, migrations): gpt-5.6 — it's
  effectively free on the Codex subscription. When throughput matters more than depth, grok-4.6
  is the fast/cheap pick; glm-5.3 for long-horizon agentic coding, flat-rate on the GLM Coding Plan.
- Orchestrator discipline: a session whose main model is fable-5 or opus-5 spends that model on
  judgement — talking to me, decomposing the task, dispatching subagents, and reviewing what they
  return. Grunt work (mechanical edits, renames, doc updates, searches, data collection, running
  commands) goes to `task` subagents on the cheap models above. The expensive model edits files
  directly only when the change itself is judgement-bound: API design, tricky refactors,
  user-facing copy.
- Anything user-facing (UI, copy, API design) needs taste ≥ 7 — that is opus-5 or fable-5 only.
  gpt-5.6, grok-4.6, and glm-5.3 do not qualify, regardless of how mechanical the task looks.
- Reviews of plans/implementations: fable-5 or opus-5, optionally gpt-5.6 as an extra independent
  perspective. Never review with glm-5.3 — lowest intelligence and taste in the table.
- Never use Haiku.

Mechanics — omp (default agent):

- omp is provider-agnostic: one binary talks to Anthropic, OpenAI, xAI, Z.ai, or any
  OpenAI-compatible endpoint. Every model in the table is reachable directly, so no wrapper tricks
  and no Codex CLI detour. Prefer omp over Claude Code whenever the work wants a non-Claude model.
- Bind the table to model roles rather than switching models by hand. Roles: `default` (main work),
  `plan`, `slow` (hardest problems), `task` (subagents), `smol`/`tiny` (titles, commit messages),
  `vision`, `designer` (UI work), `advisor` (watches every turn, can interrupt). Each role also
  takes a thinking level: minimal, low, medium, high, xhigh, max.
- Suggested binding from the table: default → gpt-5.6, slow → fable-5:high, plan → opus-5,
  designer → opus-5 (taste ≥ 7 rule), task → grok-4.6, smol/tiny → glm-5.3 or sonnet-5:minimal,
  advisor → opus-5.
- Set fallback chains (`retry.fallbackChains`) so a rate-limited primary drops to the next model
  instead of killing the session — grok-4.6 and glm-5.3 are the sane fallbacks for anything that
  isn't user-facing.
- Research/investigation: spawn the `explore` subagent — it runs in an isolated process with its own
  git worktree and reports back without polluting the main session context. Reach for `quick_task`
  when the work is mechanical; it runs on the cheap model with minimal reasoning. Bundled
  subagents: explore, plan, designer, reviewer, task, quick_task. Custom ones drop under
  `~/.omp/agent/agents/` or `.omp/agents/`.
- omp can shell out to `omp` for a self-contained research pass. Use it when I want a different
  model's read on something without changing the current session's roles.
- Config lives under `~/.omp/agent/`; sessions persist as JSONL and can be resumed, forked, and
  branched. The project ships multiple releases per day, so pin a version if reproducibility matters.

Mechanics — Claude Code (fallback):

- Only here does the model parameter restrict me to Claude (sonnet-5, opus-5, fable-5), reached via
  the Agent/Workflow model parameter.
- gpt-5.6 in Claude Code is only reachable through the Codex CLI — `codex exec` / `codex review`
  (my ~/.codex/config.toml defaults to gpt-5.6). Use the codex-implementation, codex-review, and
  codex-computer-use skills; for work they don't cover, run `codex exec -s read-only` directly with
  a self-contained prompt.
- To use a non-Claude model inside a workflow or subagent, spawn a thin Claude wrapper agent with
  `model: 'sonnet', effort: 'low'` whose prompt instructs it to write a self-contained prompt, run
  the foreign CLI via Bash, and return the raw output. If I'm reaching for this wrapper more than
  once in a session, that's the signal to move the task to omp instead.
## Sentry

- Use the `sentry` CLI for Sentry issues, events, projects, releases, traces, logs, and authenticated API work.
- Prefer dedicated `sentry` subcommands before falling back to raw `sentry api` calls.
- Never expose or commit Sentry tokens, DSNs, project credentials, or CLI authentication state.
