---
name: worktree-task
description: Complete a coding task in an isolated Git worktree, merge the verified result back into the primary worktree, and remove the temporary worktree. Use when the user invokes worktree-task or requests this full worktree lifecycle.
---

# Worktree task

Carry the user's requested task through isolation, implementation, validation, local integration, and cleanup. Invoking this skill authorizes creating a task branch and worktree, committing the task changes, merging them into the primary checkout's branch, and removing the worktree and merged task branch created for this task. Do not ask again for these ordinary lifecycle steps. This does not authorize pushing, publishing, or deleting pre-existing worktrees or branches.

## Establish the destination

- Read repository instructions and inspect `git worktree list --porcelain`, the current branch, and working-tree status before editing.
- Identify the primary checkout and record its absolute path, checked-out branch, and starting commit. “Main worktree” means the primary checkout, not necessarily a branch named `main`. Honor an explicitly named destination. Ask only if the destination is ambiguous or detached.
- Record pre-existing changes and preserve them. Never reset, clean, overwrite, or manually stash unrelated work. If existing uncommitted changes are needed for the task, establish how to include them without moving or committing someone else's work before proceeding.

## Work in isolation

- Create a uniquely named task branch from the recorded destination commit and a new worktree outside the primary checkout, following repository naming conventions. Use an explicit base commit with `git worktree add -b`.
- Run edits, builds, tests, and Git commands in that worktree using explicit working directories. Read any additional instructions there. Configure local dependencies as needed without committing secrets or machine-specific files.
- If this conversation already has a dedicated task worktree, reuse it only when its purpose and destination are clear. Track ownership: cleanup authorization covers worktrees and branches created for this task, not arbitrary existing ones.
- Finish the requested implementation, inspect the diff, and run the repository's full required gate, including applicable lint, typecheck, tests, and documentation checks. Run Gradle tasks with `-q --console=plain`.
- Commit only the task's changes, staging specific paths or hunks. Do not amend existing commits unless requested.

## Merge back and clean up

- Recheck the destination branch, HEAD, and status immediately before integrating. If its branch changed, do not silently retarget. If it has uncommitted work, leave it intact and report that integration is blocked until the checkout is ready; keep the task worktree and commits.
- If the destination branch advanced, integrate its current tip into the task branch, resolve conflicts that are clear from the task, and validate the combined result. Ask when a conflict requires choosing between competing user intent.
- Merge into the recorded branch from the primary checkout. Prefer `git merge --ff-only` after incorporating destination changes into the task branch, unless repository policy requires another merge strategy. Never reset or force-update the destination to make integration succeed.
- Verify that the task commit is an ancestor of the destination HEAD and the integrated result passed the required checks. If integration changes the tested tree, run the required gate on that result before cleanup. On failure, keep the worktree available and fix the problem within scope.
- Before removing the task worktree, check for uncommitted, untracked, and ignored files. Preserve any user-owned or non-reproducible material; remove only known disposable task outputs if needed. Move the shell's working directory to the primary checkout, then use `git worktree remove` without force. Delete the task-created branch with `git branch -d` only after confirming it is merged. Do not use recursive deletion or force flags as a workaround.
- If the task produced no changes, remove the clean task-created worktree and branch without manufacturing a commit. Never remove the primary checkout.

Report the completed change, validation, destination branch and commit, and whether worktree cleanup succeeded. If anything blocks completion, state exactly what remains and where the preserved work lives.
