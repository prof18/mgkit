---
name: quick
description: "Do a small, clear change directly, without a plan: state the change in one line, implement it test first, run the gate, commit, then run a repeating review-and-fix on the whole change and stop for the user's code review. Switches to build on its own, without asking, when the change turns out bigger or less clear than it looked. Use whenever the user starts a request with quick (quick: fix X, quick rename Y), says just do it, no plan, skip the plan, or asks to implement and review a small change without planning."
---

# Quick

Take one small change from request to reviewed commit without a plan. This skill skips planning only; every guardrail of `execute-plan` stays.

Every skill named below is read from this skill's directory by relative path (for example `../execute-plan/SKILL.md`). If a path cannot be resolved, find `skills/<name>/SKILL.md` inside the mgkit installation.

## 1. Fit check

Before changing anything, check that the change fits. It fits when all of these hold:

- You can say what changes in one or two sentences.
- It touches a handful of files at most, in one area of the code.
- No decision is open: no choice between approaches, no new dependency, no data migration, no public API or file format change the user has not spelled out.
- You would not have to guess anything the user did not say.

If it does not fit, change nothing and switch to `build` on your own: say which condition failed in one line, then read `../build/SKILL.md` and follow it on the same request from its stage 1. Do not ask first and do not make the user retype the request; build stops at its plan checkpoint before any code is written, so the switch is safe.

## 2. Stages

1. **Ticket.** If the request names a ticket (a task note, board card or issue, by path, link or id), read `../land/references/tickets.md` and move it to in progress as it says. If the request names none, skip this stage.
2. **Read.** Read the repository's instruction files (AGENTS.md, CLAUDE.md, contributing docs) and the code the change touches. Find the gate command there; without one, use the project's test and lint commands, and say which.
3. **Say it.** Write one line: what will change and where. Do not wait for a reply; the user can redirect in their next message.
4. **Base.** Record the current commit hash (`git rev-parse HEAD`) as the base.
5. **Implement.** Follow rules 4, 5, 7, 8 and 13 of `../execute-plan/SKILL.md` section 2: test first for every behaviour change, a green gate before committing without weakening tests, explicit staging, never pushing, and the repository's commit message convention. Prefer one commit.
6. **Grows mid-way.** If the work stops fitting the fit check while you implement (more files, an open decision, a guess), stop implementing and switch to `build` on your own. Leave the work uncommitted, say in one line what is done and which condition failed, then follow `../build/SKILL.md` from its stage 1 on the same request. The plan must start from the uncommitted work: name the touched files in it and say what is already done. Never improvise a design decision.
7. **Review.** Read `../review-and-fix/SKILL.md` and follow it on the whole change from the base commit to `HEAD`, with its default repeating passes. The work is committed, so it commits its fix batches, staging explicit paths. Do not run a separate single-pass review before the commit; this review covers the change.
8. **Checkpoint: the user reviews the code.** Stop. Report the commit range (`<base>..HEAD`), commits (hash and subject), the gate result and the review summary. Do not push, merge or open pull requests. Add one line on what can follow the user's approval: `squash` (`../squash/SKILL.md`) tidies fix commits into the commits they fix, and `land` (`../land/SKILL.md`) merges a worktree branch into the primary checkout and cleans up.

## 3. Rules

- Never skip the review or the checkpoint, even if the user asked not to be asked anything. In that case keep the checkpoint message to three lines.
- Never write a plan file. If the change needs one, it is not a quick change.
- Everything `execute-plan` forbids stays forbidden here: pushing, `git add -A`, `git add .`, `git commit -a`, editing outside the repository.
