# Changelog

All notable changes to mgkit. Versions stay 0.0.x until the toolkit is declared stable.

## [Unreleased]

### Added

- `review-and-fix`: one bounded review pass that grades findings and fixes only confirmed ones.
- `explain-commit`: Visual walkthroughs of a commit, range, PR or diff.
- `worktree-task`: Do a task in an isolated Git worktree, then merge back and clean up.
- `renovate-update-loop`: Process Renovate update PRs locally one by one with full validation.
- `renovate-pr-pass`: Merge green Renovate PRs and trigger rebases for blocked ones.

### Changed

- Renamed iterative-codebase-review to review-and-fix.
