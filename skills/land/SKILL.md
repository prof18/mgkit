---
name: land
description: "Land finished work from a Git worktree: fast-forward the primary checkout's branch to the worktree branch (rebasing and rerunning the gate when the target moved on), remove the worktree and its merged branch, and mark the ticket the work came from as done. Never pushes. Use when the user says land, land it, merge back into the main worktree, merge and clean up, or merge, delete the worktree and move the ticket to done, for example after the code review at the end of quick or build."
---

# Land

Finish work that is committed, has passed the gate and has been reviewed in a linked Git worktree. Do three things in order: merge it into the primary checkout, clean up the worktree, and mark its ticket done.

Invoking this skill authorizes the fast-forward merge, a rebase of the task branch when the target moved on, and removing this worktree and its merged branch. It never covers pushing, merge commits, or deleting anything else. If a check fails, stop, report what you found and ask; never work around it.

## 1. Resolve the targets

- **Worktree and branch.** Use the worktree this session worked in, or the one the user names. Read its path and branch from `git worktree list`. If more than one worktree could be meant, ask which.
- **Primary checkout and target.** The primary checkout is the first entry of `git worktree list`. Its checked-out branch is the target. If it is detached, or the user expects a different branch, ask before merging.
- **Ticket.** The task note, board card or issue the work came from. Read `references/tickets.md` (relative to this skill's directory) and find it as its "Find the ticket" section says.

## 2. Preflight

Stop on the first failure:

- **Worktree is clean.** `git -C <worktree> status --short` shows no modified files and no untracked files that are not ignored. Ignored local setup files are fine.
- **Primary checkout is clean.** No modified tracked files. Untracked files are fine.
- **Fast-forward is possible.** `git -C <primary> merge-base --is-ancestor <target> <branch>` succeeds. If it fails, the target moved on after the branch was cut:
  1. List the commits on the target that the branch lacks.
  2. Rebase the branch onto the target in the worktree: `git -C <worktree> rebase <target>`.
  3. Run the repository's full gate in the worktree.
  4. Continue only if the rebase was conflict-free and the gate is green.
  - **Rebase conflict:** run `git -C <worktree> rebase --abort`, report the conflicting files and ask.
  - **Gate fails:** stop and report the failure.
  - Never create a merge commit unless the user asks for one.
- **Ticket status is known.** You know which value means done for this tracker, as the "Know the status value" section of `references/tickets.md` says.

If the branch still has fix commits that belong in earlier ones, mention that `squash` can tidy them (`../squash/SKILL.md`, relative to this skill's directory). Run it only if the user asks.

## 3. Merge

```sh
git -C <primary> merge --ff-only <branch>
git -C <primary> log --oneline <old-target>..<target>
```

A fast-forward makes the target identical to the branch tip, which passed the gate, so do not run the gate again.

## 4. Clean up

Move the shell out of the worktree first if it is inside it. Then run:

```sh
git -C <primary> worktree remove <worktree>
git -C <primary> branch -d <branch>
```

- Never pass `--force` to `worktree remove` or `-D` to `branch`. A refusal means something is still unmerged or uncommitted: report it and ask.
- Remove only this worktree and this branch. Leave every other worktree alone, including ones that look stale.

## 5. Mark the ticket done

Change the status to the done value as the "Change the status" section of `references/tickets.md` says: only the status field of a local note, and ask first for a hosted tracker unless the user already asked for it.

## 6. Report

Report in a few lines:
- The target branch and the commit range it moved over.
- Whether a rebase was needed, and the gate result if it was.
- The worktree path and the branch that were removed.
- The ticket now marked done, or why there was none.
- That nothing was pushed.

Then offer to push the target branch. Push only if the user says yes.
