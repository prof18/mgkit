# Changelog

All notable changes to mgkit. Versions stay 0.0.x until the toolkit is declared stable.

## [Unreleased]

### Added

- `squash`: tidies a branch's unpublished commits into the shape that reads best. Review and test fixes fold into the commit they fix, separate concerns stay separate commits, a small cohesive change becomes one commit, and the final tree is checked to be identical. It never pushes and refuses commits that are already on a remote.
- `land`: finishes work from a Git worktree. It fast-forwards the primary checkout's branch (rebasing the task branch and rerunning the gate when the target moved on), removes the worktree and its merged branch without force, and marks the ticket the work came from as done, asking first for hosted trackers. It never pushes.
- `quick` and `build` mention `squash` and `land` at their final checkpoint.

## [0.0.9] - 2026-11-05

### Changed

- `plan` and `plan-max` build plans from a fixed component catalog (steps, tasks, decisions, user tasks, file lists, diffs, callouts, out-of-scope lists, static SVG diagrams). The agent writes only the page body; the bundled bash script `skills/plan/scripts/assemble-plan.sh` adds the shared stylesheet, checks for leftover placeholders, inline styles, scripts or external resources, unknown classes and steps missing a required part, then writes the file. The planning agent no longer reads or writes the stylesheet, so plans cost fewer tokens and look the same everywhere. `plan-review` runs the same checks after editing a plan.

## [0.0.8] - 2026-11-05

### Added

- `quick`: do a small, clear change without a plan. It states the change in one line, implements it test first behind the gate, commits, runs a repeating review-and-fix on the whole change and stops for your code review. It stops and recommends `build` when the change turns out bigger or needs a decision. `build` mentions `quick` when the change it is asked for is tiny.

## [0.0.7] - 2026-11-04

### Changed

- `plan-review` and `review-and-fix` repeat passes on their own instead of asking you to re-run them. Another pass starts only when the last one fixed a medium-or-worse finding; `plan-review` stops after at most 4 passes and `review-and-fix` after 3, with one report for the whole run. Say "single pass" for the old behaviour. The per-commit reviews inside `execute-plan` stay single pass; `execute-plan` now ends with one repeating review-and-fix on the whole change from its base commit, which `build` uses as its final review. The big-plan `/goal` kickoff lines wait for that final review.

## [0.0.6] - 2026-10-27

### Added

- Review panel for `plan-review` and `review-and-fix`: the other installed agent CLIs (Claude Code, Codex, Pi) review read-only next to the driving agent, then up to 3 driver-moderated rounds settle the findings. Code-review findings and decisions appear per author in Difftray. Seats and models are set in `~/.config/mgkit/panel.conf`, including a fallback model for the pi seat when its model is rate-limited and the pi extensions it may load.

### Changed

- `scripts/install-check.sh opencode` works on OpenCode 2, which removed `opencode debug skill`: it installs the committed state with `opencode plugin add` into an isolated XDG home and checks the skills the installed copy registers through `setup()`. OpenCode 1 keeps the old check.
- `docs/harnesses.md` documents how to update mgkit in Claude Code, Codex, OpenCode and Pi, and records the harness versions re-verified on 2026-10-19.
- `scripts/check.sh` no longer forbids skills from naming Difftray.

## [0.0.5] - 2026-10-19

### Added

- `plan-to-docs`: turn finished plans into present-tense docs written from the code, record the decisions that lived only in the plans, point `AGENTS.md` at the docs, fix every link to the plans and delete them once you agree. Its writing guide adapts chrisbanes/skills `grounded-writing` (Apache-2.0) and mattpocock/skills `writing-for-agents` (MIT).

## [0.0.4] - 2026-10-14

### Fixed

- Quote the `description` frontmatter of the `build` and `execute-plan` skills. The unquoted values contained `: `, which YAML rejected as a nested mapping, so harnesses failed to load both skills.

## [0.0.3] - 2026-10-14

### Changed

- Make the OpenCode plugin speak both host generations from one launcher file: OpenCode 2 reads its `setup()` and registers every mgkit skill through the skill transform, while OpenCode 1 (1.18.29+) keeps the `config` hook that appends `skills/` to `skills.paths`. The file still exports exactly one thing, now the default object.

## [0.0.2] - 2026-09-22

### Changed

- Prefer one implementation commit for small, cohesive features; split larger work at meaningful boundaries that improve reviewability, readability, rollback safety, or separate distinct concerns.
- Align planning templates and execution with explicit commit groupings instead of requiring a commit per step or task, preserving tests, gates, staged review, and human checkpoints.
- Track shared commits and interrupted work across grouped tasks, and record verified commits for verification-only tasks without creating empty commits.
- Point installation commands at the public `prof18/mgkit` repository.

## [0.0.1] - 2026-09-17

### Added

- `review-and-fix`: one bounded review pass that grades findings and fixes only confirmed ones.
- `explain-commit`: visual walkthroughs of a commit, range, PR or diff.
- `worktree-task`: do a task in an isolated Git worktree, then merge back and clean up.
- `renovate-update-loop`: process Renovate update PRs locally one by one with full validation.
- `roast`: critique an idea, question the user in rounds until decisions are settled, hunt for a name, write a roast file.
- `plan`: write a small feature plan as one standalone HTML file a cheaper agent can execute.
- `plan-max`: write a multi-file plan (index, milestone files, TODO.md) for big features, with kickoff lines per harness.
- `plan-review`: one-pass review of a small or big plan that fixes findings in place and reports.
- `execute-plan`: implement a small plan in one run or a big plan task by task from TODO.md, with test-first changes, gate, review and explicit staging.
- `build`: run plan, plan-review, execute-plan and review-and-fix end to end, stopping for the user to check the plan and the code.
- `renovate-pr-pass`: merge green Renovate PRs and trigger rebases for blocked ones.
- Packaging for Claude Code, Codex, OpenCode and Pi from one shared `skills/` folder.
- `scripts/check.sh` gate, `scripts/bump-version.sh`, `scripts/install-check.sh`, and six behaviour evals.

### Changed

- Renamed iterative-codebase-review to review-and-fix.
