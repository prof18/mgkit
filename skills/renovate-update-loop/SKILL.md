---
name: renovate-update-loop
description: Process Renovate dependency-update pull requests locally, one by one, by rebasing each branch onto the latest base branch, running the repository's authoritative local validation, fixing update fallout, and merging successful updates. Use when the user asks to handle, clear, test, or merge Renovate updates locally.
---

# Renovate Update Loop

Process open Renovate updates sequentially. Rebase each branch onto the latest base branch,
verify it with the repository's own local gate, and merge it before starting the next update.
Keep the workflow observable and preserve the repository's established Git and validation
conventions.

## Discover the repository workflow

Before changing branches:

1. Read the repository instructions (`AGENTS.md` and any linked build/release docs).
2. Identify the default branch, remote, authoritative local gate, merge method, and any
   required final integration or E2E suite. Do not assume they match another project.
3. Require a clean working tree. Do not stash or discard user work; stop and ask if tracked
   or untracked changes would make branch switching unsafe.
4. Confirm `gh` is authenticated and the required local toolchain is available.

Invoking this skill authorizes the branch switching, rebasing, update-branch pushes, and PR
merges needed for this workflow. It does not authorize unrelated repository changes.

## Process updates sequentially

### 1. Refresh the base branch

Check out the repository's default branch and fast-forward it from its configured remote.
Never use a destructive reset.

### 2. List open Renovate PRs

Use GitHub CLI and include the PR number, title, head branch, draft state, mergeability, and
status checks. Query the Renovate GitHub App first and fall back to the classic bot account
when necessary.

Prefer low-risk patch and minor library updates first. Leave majors and compiler/build-tool
updates for last so a difficult update does not block independent simple ones.

### 3. Rebase the next update

Fetch the remote update branch, check it out locally, and rebase it onto the current base
branch.

Resolve only mechanical dependency conflicts:

- Keep the intended newer dependency version when version-pin files conflict.
- Regenerate dependency locks, verification metadata, generated projects, or equivalent
  derived files using the repository's documented command; do not hand-merge generated
  output.
- Stop and ask when a conflict changes production behavior or is otherwise non-mechanical.

Continue the rebase only after reviewing the resolved diff.

### 4. Run the authoritative local gate

Run the exact full gate documented by the repository. Do not substitute generic Gradle,
Xcode, npm, or test commands when the project provides a canonical script.

If the gate fails:

- When the dependency update caused an API or compatibility failure, make the smallest
  source change needed on the Renovate branch, add or update tests when behavior changes,
  and rerun the full gate.
- When the failure is unrelated or pre-existing, stop and report it without merging.
- When a major compiler, build-tool, or framework update requires an architectural choice,
  stop and present the decision instead of forcing it through.

### 5. Update and merge the PR

Because rebasing rewrites the Renovate branch, push it with `--force-with-lease`; never use an
unqualified force push. If the repository has hosted required checks, wait for them to pass.
Then merge with the repository's established merge method and delete the remote update branch
when that is normal for the project.

If the repository intentionally uses only a local gate, do not invent a hosted-check
requirement. The successful local gate remains the evidence for merging.

### 6. Refresh and repeat

Return to the default branch, fast-forward it, verify that the merged update landed, refresh
the open Renovate PR list, and repeat with the next processable update. Never rely on the
original PR or mergeability snapshot after the base branch moves.

## Final validation

After all processable updates land, remain on the latest default branch and run any final
integration, device, Maestro, release, or cross-platform suite required by the repository's
instructions. Run optional expensive suites only when the repository or user requires them.

Report:

- PRs and branches merged
- Updates skipped or blocked, with the exact reason
- Final default-branch commit
- Local gate result and any required final-suite result
- Paths to generated reports or logs when applicable

## Guardrails

- If the user asks only for inspection or a report, do not switch branches, push, comment,
  or merge.
- Never merge an update whose authoritative local gate failed.
- Never discard local changes or weaken tests, lint, or verification to make an update pass.
- Keep update-specific compatibility fixes on the Renovate branch.
- Use network or credential escalation only when the environment requires it.
