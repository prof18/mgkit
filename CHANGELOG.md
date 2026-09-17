# Changelog

All notable changes to mgkit. Versions stay 0.0.x until the toolkit is declared stable.

## [Unreleased]

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
