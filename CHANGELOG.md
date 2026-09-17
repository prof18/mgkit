# Changelog

All notable changes to mgkit. Versions stay 0.0.x until the toolkit is declared stable.

## [Unreleased]

### Added

- `review-and-fix`: one bounded review pass that grades findings and fixes only confirmed ones.
- `explain-commit`: Visual walkthroughs of a commit, range, PR or diff.
- `worktree-task`: Do a task in an isolated Git worktree, then merge back and clean up.
- `renovate-update-loop`: Process Renovate update PRs locally one by one with full validation.
- `roast`: critique an idea, question the user in rounds until decisions are settled, hunt for a name, write a roast file.
- `plan`: write a small feature plan as one standalone HTML file a cheaper agent can execute.
- `plan-max`: write a multi-file plan (index, milestone files, TODO.md) for big features, with kickoff lines per harness.
- `renovate-pr-pass`: Merge green Renovate PRs and trigger rebases for blocked ones.

### Changed

- Renamed iterative-codebase-review to review-and-fix.
