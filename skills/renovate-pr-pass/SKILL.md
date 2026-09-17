---
name: renovate-pr-pass
description: Review open Renovate pull requests in the current GitHub repository, merge Renovate PRs whose required checks have passed even if they became stale after earlier Renovate merges moved `main`, and trigger `@renovate rebase` on Renovate PRs with failing checks, pending checks, or real mergeability issues. Use when the user asks to clean up Renovate PRs, merge green Renovate updates, rebase blocked or outdated Renovate branches, or run a routine Renovate maintenance pass.
---

# Renovate PR Pass

Use GitHub CLI against the current repository. Prefer `gh pr` commands over local branch checkouts.

## Workflow
1. List open Renovate PRs:

```bash
gh pr list --state open --search "author:app/renovate" --json number,title,url,isDraft,mergeStateStatus,statusCheckRollup
```

If the repository uses the classic Renovate bot account instead of the GitHub App, rerun with `--search "author:renovate[bot]"`.

2. Classify each PR:
- Merge candidate if it is not a draft and every relevant check run in `statusCheckRollup` is `COMPLETED` with `SUCCESS`. Treat a non-`CLEAN` `mergeStateStatus` caused by earlier Renovate merges moving `main` as still mergeable enough to try.
- Rebase candidate if any relevant check failed, any required check is still pending, or the PR is a draft.
- Ignore non-Renovate PRs if a broader query is used.

3. Merge green PRs sequentially:

```bash
gh pr merge <number> --squash --delete-branch
```

Merge sequentially because every successful merge moves `main` and can make later Renovate PRs stale.

If `gh pr merge` reports that a PR is not mergeable, move it into the rebase set instead of stopping the pass.

4. Refresh the open Renovate PR list after the merge batch. Do not trust the original mergeability snapshot.

5. Merge any remaining open Renovate PRs that are still fully green even if `mergeStateStatus` is now stale/non-clean after earlier merges moved `main`:

```bash
gh pr merge <number> --squash --delete-branch
```

Again, if `gh pr merge` reports that a PR is not mergeable, move it into the rebase set.

6. Trigger a rebase on every remaining open Renovate PR with failed checks, pending checks, or a real mergeability error from `gh pr merge`:

```bash
gh pr comment <number> --body "@renovate rebase"
```

7. Summarize the result:
- Merged PR numbers and titles
- Rebasing-triggered PR numbers and titles
- Any skipped PRs and why they were skipped

## Guardrails
- If the user asks only for an inspection or report, do not merge or comment.
- Do not merge Renovate PRs with pending or failed checks.
- Do not send `@renovate rebase` just because a previously green Renovate PR became stale after earlier merges moved `main`; try the merge first.
- If `gh pr merge` reports that a PR is not mergeable, reclassify it into the rebase set.
- Use squash merge unless the user explicitly asks for another merge strategy.
- If GitHub CLI commands fail because of network or sandbox limits, rerun them with escalated permissions.

## Output Style
- Keep the final report brief.
- Separate merged PRs from rebased PRs.
- Note when a stale-but-green PR was merged anyway after earlier merges moved `main`.
