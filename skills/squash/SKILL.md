---
name: squash
description: "Tidy the commits of a branch into the shape that reads best, keeping the code exactly the same: fixes fold into the commit they fix, separate concerns stay separate commits, and a small cohesive change becomes one commit. Use when the user says squash, squash the commits, tidy the commits, clean up the history, make it one commit, or fold the review fixes in, for example after review-and-fix left fix commits on top of the work."
---

# Squash

Turn a branch's commits into the history a reviewer would want to read: one commit per meaningful, independently understandable change. Fixes for commits in the same range do not get commits of their own. If the user names a shape ("make it one commit", "keep the refactor separate"), follow it.

Invoking this skill is the user's request to rewrite the branch's unpublished history: resets, rebases and rewording. It never covers pushing.

## 1. Branch and base

- **Branch.** Use the branch this session worked on, or the one the user names. If it is checked out in a worktree, run every command there with `git -C <path>`.
- **Base.** The commit the branch started from:
  - For a branch in a linked worktree: `git merge-base HEAD <target>`, where `<target>` is the branch checked out in the primary checkout (the first entry of `git worktree list`).
  - Otherwise: the merge-base with the repository's default branch (`git symbolic-ref --short refs/remotes/origin/HEAD`, else `main`).
  - A range or commit count the user names wins over both.
- List the range with `git log --oneline <base>..HEAD`:
  - Zero or one commit: say there is nothing to do and stop.
  - Any merge commit in the range: stop and ask.

## 2. Preflight

Stop on the first failure:

- **No tracked changes.** `git status --short` shows no modified tracked files. Untracked and ignored files are fine.
- **Nothing published.** `git branch -r --contains <oldest commit in the range>` prints nothing. A commit on a remote would need a force push to rewrite, so stop and ask.

## 3. Decide the shape

Read each commit's message and diff (`git show --stat <commit>`, then the full diff where needed). Group the commits:

- **Fold into its target.** A commit that fixes or adjusts an earlier commit in the range folds into it. Examples: review fixes, test and lint fixes, typos, renames, a half-finished step completed later. A commit and its later revert that cancel out completely are both dropped.
- **Keep separate.** A distinct concern that a reviewer could understand, and someone could revert, on its own stays its own commit. Examples: a refactor the feature builds on, a dependency bump, an unrelated fix. Keep the original order between groups.
- **One commit.** A small, cohesive change becomes one commit, whatever number of steps built it.
- **Never split a commit.** Only fold, reorder, reword and drop.

`execute-plan` uses the same commit-grouping rule: rule 12 in section 2 of `../execute-plan/SKILL.md`, relative to this skill's directory.

- If the current shape is already the best one, say so and stop.
- If two shapes are equally reasonable, pick the one with fewer commits.
- Ask only when commits mix concerns in a way folding cannot fix.

Write each resulting commit's message to a temporary file outside the repository:
- **Subject.** It describes that commit's change and follows the repository's commit convention.
- **Body.** Start from the main commit's body and work in what each folded commit changed, as part of the change rather than as history. Drop `fixup!` subjects and lines like "address review".
- **Trailers.** Follow the user's own instructions on co-author or attribution trailers.

## 4. Rewrite

Record the old tip first: `OLD=$(git -C <path> rev-parse HEAD)`.

**One resulting commit:**

```sh
git -C <path> reset --soft <base>
git -C <path> commit -q -F <message-file>
```

**Several resulting commits:** write a rebase todo file and run a non-interactive rebase.
- Each group is `pick` for its first commit, then `fixup` for each commit folded into it, moved up next to its target when needed.
- End each group with `exec git commit --amend -q -F <that group's message file>`.
- Leave dropped commits out of the todo.

```sh
GIT_SEQUENCE_EDITOR="cp <todo-file>" git -C <path> rebase -i <base>
```

If the rebase stops on a conflict, a moved fixup did not apply out of order:
1. Run `git -C <path> rebase --abort`.
2. Plan again with that commit left in place. Fold it into the commit before it if that is the same concern; otherwise keep it separate.
3. If that conflicts too, abort and report.

## 5. Verify

```sh
git -C <path> diff --quiet "$OLD" HEAD && echo same-tree
git -C <path> log --oneline <base>..HEAD
```

- **If the tree differs or a step failed:** abort any rebase in progress, run `git -C <path> reset --soft "$OLD"`, report `$OLD` and stop.
- **No new gate run.** The final tree is identical to the one that passed the gate, so do not rerun it. Intermediate commits are not gated on their own.
- **Hooks.** Never bypass hooks with `--no-verify`.

## 6. Report

Report in a few lines:
- The old shape and the new one, for example `5 → 2`.
- Each new commit's hash and subject, with the old commits folded into it.
- Any commits dropped because they cancelled out.
- That the tree is unchanged.
- That nothing was pushed.
