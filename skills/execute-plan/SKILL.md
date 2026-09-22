---
name: execute-plan
description: Implement an existing plan written by plan or plan-max. A single HTML plan file is executed in one run; a plan folder is worked through TODO.md task by task until done, under a long-running goal when the harness has one. Enforces test-first changes, a green gate, review-and-fix before committing, explicit staging, and never pushing. Use whenever the user says execute the plan, implement the plan, continue the plan or run the plan, with or without a path: the skill finds plans under plan/ itself and reports when there is none.
---

# Execute Plan

Implement a plan exactly as written, with commits sized for feature scope and reviewability.

## 1. Resolve the plan

- The argument is a path. Without one, look under `plan/` (or the plan location the user's instructions define) for unfinished plans: every `.html` file, and every folder whose `TODO.md` still has an unchecked box that is not a USER TASK. Sort newest first. If exactly one exists, use it and say so; otherwise ask which one. If none exists, say that no plan was found, where plans are expected, and stop without changing anything.
- An `.html` file means **single-run mode**. A folder containing `TODO.md` means **loop mode**. Anything else: stop and say what was expected.

## 2. Rules for both modes

1. Read the plan's own instructions first: the whole file in single-run mode; `INDEX.html` and `00-conventions.html` in full in loop mode. Where the plan is stricter than these rules, the plan wins.
2. Read the repository's instruction files (AGENTS.md, CLAUDE.md, contributing docs).
3. Code samples in HTML plans are escaped. Decode `&lt;`, `&gt;` and `&amp;` when transcribing.
4. Test first for every behaviour change: write the test, run it and watch it fail, implement, run it and watch it pass.
5. Run the plan's gate command before every commit. Never commit on a red gate. Never weaken, skip or delete tests to get green.
6. Review before committing: read `../review-and-fix/SKILL.md` (relative to this skill's directory; if that path cannot be resolved, find `skills/review-and-fix/SKILL.md` in the mgkit installation) and follow it on the staged change. Do this before every commit, including intermediate commits.
7. Stage explicit paths only. Never run `git add -A`, `git add .` or `git commit -a`. Never stage anything under `plan/` or wherever the plan lives. Run `git status --short` before every commit.
8. Never push, never add remotes, never publish, unless the user explicitly asks in this conversation.
9. Never edit the plan, except `TODO.md` in loop mode.
10. When reality contradicts the plan (an API differs, a file is missing, a decision cannot be implemented), do not improvise. In loop mode, write `BLOCKED: <reason and evidence>` indented under the task and continue with tasks that don't depend on it. In single-run mode, stop and report.
11. Never perform or self-certify a USER TASK.
12. Prefer one implementation commit for a small, cohesive feature. Split only at meaningful, independently understandable boundaries that improve reviewability, readability, rollback safety, or separate distinct concerns. Larger work should use small, coherent commits where those boundaries provide value. Multiple steps or tasks alone do not justify multiple commits. Follow explicit commit groupings in the plan; otherwise state the grouping before implementation.
13. Follow the repository's commit message convention; without one, use `<area>: <imperative summary>`.

## 3. Single-run mode (one HTML file)

1. Execute the steps in order, keeping their tests and acceptance checks. Commit at the chosen boundaries, grouping all steps of a small, cohesive feature into one implementation commit by default.
2. Before each commit, stage explicit paths, run the gate, and run review-and-fix on the staged change. For one commit, this reviews the full implementation.
3. No goal mode is needed; do not ask for one.
4. Finish with: steps done, commits (hash and subject), gate result, review summary, remaining USER TASKs.

## 4. Loop mode (plan folder)

1. Loop:
   1. Re-read `TODO.md`.
   2. Pick the first unchecked task that is not a USER TASK and does not depend on a blocked task.
   3. Read its milestone file (the whole file the first time you enter a milestone; afterwards the task's section).
   4. Implement it, test first, and run its acceptance checks. If the chosen commit groups related tasks, repeat for those tasks in order before committing. Leave them unchecked until committed; record implemented but uncommitted task ids in `TODO.md` if interrupted or blocked.
   5. Stage explicit paths and run the gate.
   6. Run review-and-fix on the staged change.
   7. Commit the completed group at its meaningful boundary. Do not create an empty commit for a verification-only task; record the verified commit instead.
   8. Tick only completed tasks `[x]` in `TODO.md` and record their commit hash (a shared hash is valid).
   9. Repeat.
2. At a milestone boundary, run the milestone acceptance checks before starting the next milestone. If they fail, fix that first.
3. **Keep going.** If this session runs under a goal or long-running mode, the goal keeps you working. If it does not, keep looping yourself. Do not stop to ask whether to continue.
4. Stop only when every task that is not a USER TASK is checked, when every remaining task is blocked or waits on a USER TASK, or when the context or budget is nearly used up.
5. Before stopping for any reason, add one line under `## Log` in `TODO.md` (date, tasks done, blockers). Then report: progress (done out of total tasks), commits, blockers, pending USER TASKs, and the exact line to continue.
6. When resuming, `TODO.md` is the only record of progress; trust it over memory of the conversation. Inspect any recorded uncommitted work before continuing; do not assume an unchecked task has no changes. Check that the last ticked task's commit exists (`git log --oneline`); if it doesn't, untick it and add a note.

## 5. Harness notes

- Claude Code and Codex have a native `/goal` mode; start big plans with it.
- OpenCode and Pi have no goal mode; this skill keeps looping by itself, and running the same line again continues from `TODO.md`.
- The exact kickoff and continue lines per harness are in `../plan-max/references/kickoff.md`. Use them when reporting how to continue.
