# Evals

Behaviour checks for the mgkit skills, run manually with Claude Code's `claude plugin eval` (Claude Code 2.1.269). They are never part of `scripts/check.sh`.

## Format (from `claude plugin eval --help` and the Claude Code "Test plugins with evals" docs)

- One directory per case under `evals/<case>/`.
- `prompt.md`: YAML frontmatter plus the prompt body sent verbatim. Fields used here: `description`, `tags`, `max_turns` (default 10), `timeout_seconds` (default 300), `allowed_tools` (read-only tools are granted when listed; others need `--allow-tools`), `runs` (default 3). Unknown keys are an error.
- `graders/<name>.md`: one grader per file, frontmatter `type` plus options, optional `weight` and `arm`.
  - `tool_used` with `tool: Skill` and `input_match: '"skill"\s*:\s*"(?:[\w-]+:)?<skill>"'` checks the skill fired (namespaced or not). Skill graders are indicators only in two-arm runs.
  - `tool_used` with `min: 0`, `max: 0`, `arm: both` asserts a tool was never called.
  - `regex` with `target: last_message` checks the final reply; JavaScript regex.
  - `llm` uses the file body as PASS/FAIL criteria; a small judge model votes three times.
- Each run starts in an empty temporary working directory with only the plugin loaded.
- By default every case also runs without the plugin (baseline arm); the report shows `WITH`, `W/OUT` and the delta.

## Running

Always pass `--no-publish`: by default the HTML report is published to claude.ai.

```
claude plugin eval . --no-publish --trust-plugin --runs 1 --allow-tools WebSearch WebFetch Write Edit
claude plugin eval . --no-publish --trust-plugin --runs 1 --case roast-name-hunt
```

Results are written to `evals/results/<timestamp>/` (gitignored).

## Cases

| Case | Checks |
|---|---|
| `roast-critique-then-round` | roast fires; critique names existing tools before questions; `❓ **Q1` / `➡️` format; no file writes |
| `roast-name-hunt` | roast fires; name table with conflicts and domain columns (regex); the name is asked as a round question (regex); no file writes |
| `plan-questions-first` | plan fires; asks questions in the round format; no file writes |
| `plan-max-suggests-plan` | plan-max fires; says the task is too small, points to `plan` or a direct fix, asks how to proceed; no file writes |
| `execute-plan-no-plan` | execute-plan fires; reports no plan found and where plans are expected; no file writes |
| `build-stops-at-checkpoint` | build fires; stops for an explicit go before implementing; no `git commit` |

## Results

### 2026-09-17 (Claude Code 2.1.269, 1 run per arm)

Final scores after two wording iterations. `WITH` is with mgkit loaded, `W/OUT` is the no-plugin baseline.

| Case | WITH | W/OUT | Δ | Iterations |
|---|---|---|---|---|
| `roast-critique-then-round` | 1.00 | 0.33 | +0.67 | passed on run 1 |
| `roast-name-hunt` | 1.00 | 0.33 | +0.67 | 2 (name hunt moved into the first message; llm grader replaced by regex graders) |
| `plan-questions-first` | 1.00 | 0.50 | +0.50 | 2 (sharper trigger; every question in round format) |
| `plan-max-suggests-plan` | 1.00 | 1.00 | 0.00 | 2 (sharper trigger; rubric accepts a direct-fix suggestion) |
| `execute-plan-no-plan` | 1.00 | 0.50 | +0.50 | 1 (sharper trigger) |
| `build-stops-at-checkpoint` | 1.00 | 0.50 | +0.50 | 1 (sharper trigger) |

Findings from run 1: `plan`, `plan-max`, `execute-plan` and `build` answered from their descriptions without loading the skill; the descriptions now name their trigger phrases explicitly. `plan-max-suggests-plan` shows no delta because the model already refuses a multi-file plan for a typo without help.

Cost: run 1 (all cases) $1.13, run 2 (five cases) $1.18444340000000004, run 3 (three cases) $.9283556.
