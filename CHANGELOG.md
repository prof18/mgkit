# Changelog

All notable changes to mgkit. Versions stay 0.0.x until the toolkit is declared stable.

## [Unreleased]

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
