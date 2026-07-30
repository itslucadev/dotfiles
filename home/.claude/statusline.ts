#!/usr/bin/env bun

import { readFileSync, writeFileSync } from "fs";
import { homedir } from "os";
import { join } from "path";

const CACHE_FILE = join(homedir(), ".claude", "statusline-quota.json");
const BURN_WINDOW_MS = 30 * 60_000;
const SAMPLE_EVERY_MS = 60_000;
const BAR_WIDTH = 10;

const colors = {
  green: "\x1b[38;5;42m",
  gold: "\x1b[38;5;220m",
  orange: "\x1b[38;5;208m",
  red: "\x1b[38;5;204m",
  dim: "\x1b[2m",
  reset: "\x1b[0m",
};

const colorFor = (percentage: number) =>
  percentage >= 80
    ? colors.red
    : percentage >= 70
      ? colors.orange
      : percentage >= 60
        ? colors.gold
        : colors.green;

const bar = (usedPercentage: number) => {
  const remaining = Math.max(0, 100 - usedPercentage);
  const filled = Math.min(BAR_WIDTH, Math.round(remaining / (100 / BAR_WIDTH)));
  return (
    colorFor(usedPercentage) +
    "●".repeat(filled) +
    colors.dim +
    "○".repeat(BAR_WIDTH - filled) +
    colors.reset
  );
};

const formatTime = (date: Date) =>
  date.toLocaleTimeString("de-DE", {
    hour: "2-digit",
    minute: "2-digit",
  });

const formatTokens = (tokens: number) =>
  tokens >= 1e6
    ? `${(tokens / 1e6).toFixed(1).replace(/\.0$/, "")}M`
    : `${Math.round(tokens / 1000)}K`;

type Sample = {
  timestamp: number;
  percentage: number;
};

function burnRate(samples: Sample[], now: number): number | null {
  let recent = samples.filter(
    (sample) => now - sample.timestamp <= BURN_WINDOW_MS,
  );
  let start = 0;

  for (let index = 1; index < recent.length; index += 1) {
    if (recent[index].percentage < recent[index - 1].percentage - 0.5) {
      start = index;
    }
  }

  recent = recent.slice(start);

  if (recent.length < 2) {
    return null;
  }

  const duration =
    recent[recent.length - 1].timestamp - recent[0].timestamp;

  if (duration < 5 * 60_000) {
    return null;
  }

  const rate =
    ((recent[recent.length - 1].percentage - recent[0].percentage) /
      duration) *
    3_600_000;

  return rate > 0.1 ? rate : null;
}

function gitSegment(directory: string): string | null {
  const result = Bun.spawnSync(
    ["git", "--no-optional-locks", "status", "--porcelain=v2", "--branch"],
    { cwd: directory },
  );

  if (result.exitCode !== 0) {
    return null;
  }

  let branch = "";
  let ahead = 0;
  let behind = 0;
  let staged = 0;
  let unstaged = 0;
  let untracked = 0;

  for (const line of result.stdout.toString().split("\n")) {
    if (line.startsWith("# branch.head ")) {
      branch = line.slice(14);
    } else if (line.startsWith("# branch.ab ")) {
      const match = line.match(/\+(\d+) -(\d+)/);
      if (match) {
        ahead = Number(match[1]);
        behind = Number(match[2]);
      }
    } else if (line.startsWith("1 ") || line.startsWith("2 ")) {
      const status = line.split(" ")[1];
      if (status[0] !== ".") {
        staged += 1;
      }
      if (status[1] !== ".") {
        unstaged += 1;
      }
    } else if (line.startsWith("u ")) {
      unstaged += 1;
    } else if (line.startsWith("? ")) {
      untracked += 1;
    }
  }

  let segment = `${branch} S:${staged} U:${unstaged} A:${untracked}`;

  if (ahead > 0) {
    segment += ` ⇡${ahead}`;
  }
  if (behind > 0) {
    segment += ` ⇣${behind}`;
  }

  return segment;
}

const input = await Bun.stdin.json().catch(() => ({} as any));
const now = Date.now();
const darkText = "\x1b[38;5;235m";

const pill = (background: number, text: string) =>
  `\x1b[38;5;${background}m\uE0B6` +
  `\x1b[48;5;${background}m${darkText}\x1b[1m${text}\x1b[22m` +
  `\x1b[49m\x1b[38;5;${background}m\uE0B4${colors.reset}`;

const pillColorFor = (percentage: number) =>
  percentage >= 80
    ? 204
    : percentage >= 70
      ? 208
      : percentage >= 60
        ? 220
        : 42;

const pills: string[] = [];
const model = input.model?.display_name ?? "?";
const directory = input.workspace?.current_dir ?? process.cwd();
const directoryName = directory.split("/").pop() ?? directory;
const cost = input.cost ?? {};
const added = cost.total_lines_added ?? 0;
const deleted = cost.total_lines_removed ?? 0;
const lineChanges = added || deleted ? ` +${added}/-${deleted}` : "";

pills.push(pill(111, directoryName));

const git = gitSegment(directory);
if (git) {
  pills.push(pill(221, git + lineChanges));
}

const contextWindow = input.context_window ?? {};
const contextPercentage = contextWindow.used_percentage ?? null;

if (contextPercentage != null) {
  const percentage = Math.round(contextPercentage);
  const icon = percentage >= 80 ? "🛑" : percentage >= 60 ? "⚠️" : "✅";
  const used = contextWindow.total_input_tokens ?? null;
  const size = contextWindow.context_window_size ?? null;
  let segment = "";

  if (used != null && size) {
    segment += `${formatTokens(used)}/${formatTokens(size)} `;
  }

  segment += `${percentage}% ${icon}`;

  if (percentage >= 80) {
    segment += " 🚨 /handoff NOW";
  } else if (percentage >= 70) {
    segment += " ⚡ /handoff";
  } else if (percentage >= 60) {
    segment += " ☝ /handoff";
  }

  pills.push(pill(pillColorFor(percentage), segment));
}

if (cost.total_cost_usd != null) {
  const segment = `$${cost.total_cost_usd.toFixed(2)}${git ? "" : lineChanges}`;
  pills.push(pill(213, segment));
}

pills.push(pill(80, model));
console.log(pills.join(" "));

const rateLimits = input.rate_limits ?? {};

if (rateLimits.five_hour?.used_percentage != null) {
  const percentage = rateLimits.five_hour.used_percentage;
  const reset = new Date(rateLimits.five_hour.resets_at * 1000);
  let samples: Sample[] = [];

  try {
    samples = JSON.parse(readFileSync(CACHE_FILE, "utf8")).samples ?? [];
  } catch {}

  if (
    samples.length === 0 ||
    now - samples[samples.length - 1].timestamp >= SAMPLE_EVERY_MS
  ) {
    samples.push({ timestamp: now, percentage });
    samples = samples.filter(
      (sample) => now - sample.timestamp <= 2 * BURN_WINDOW_MS,
    );

    try {
      writeFileSync(CACHE_FILE, JSON.stringify({ samples }));
    } catch {}
  }

  let line =
    `${colors.dim}5h${colors.reset}  ${bar(percentage)} ` +
    `${colorFor(percentage)}${Math.round(100 - percentage)}% left${colors.reset}`;
  const rate = burnRate(samples, now);

  if (rate != null) {
    line += ` 🔥 ${rate.toFixed(1)}%/hr`;
    const emptyAt = new Date(
      now + ((100 - percentage) / rate) * 3_600_000,
    );
    if (emptyAt < reset) {
      line += ` → empty ~${formatTime(emptyAt)}`;
    }
  }

  line += ` ${colors.dim}(resets ${formatTime(reset)})${colors.reset}`;
  console.log(line);
}

if (rateLimits.seven_day?.used_percentage != null) {
  const percentage = rateLimits.seven_day.used_percentage;
  const reset = new Date(rateLimits.seven_day.resets_at * 1000);
  const day = reset.toLocaleDateString("en-US", { weekday: "short" });

  console.log(
    `${colors.dim}wk${colors.reset}  ${bar(percentage)} ` +
      `${colorFor(percentage)}${Math.round(100 - percentage)}% left${colors.reset}` +
      ` ${colors.dim}(resets ${day} ${formatTime(reset)})${colors.reset}`,
  );
}
