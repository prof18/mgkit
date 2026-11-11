---
name: build
description: "Run the full mgkit pipeline for a feature: plan it, review the plan, stop for the user to check the plan, then execute it (execute-plan ends with a repeating review-and-fix on the whole change), stopping at the end for the user's code review. Use whenever the user starts a request with build (build this, build: add X), asks to take a feature end to end, or to run the whole pipeline. Never implement such a request directly; the plan checkpoint comes first. A small change the user wants done without a plan (quick: X, just do it, no plan) belongs to quick instead."
---

# Build

Take one feature from request to reviewed commits by running the other mgkit skills in order. This skill adds no method of its own, only the sequence and two mandatory human checkpoints.

Every skill named below is read from this skill's directory by relative path (for example `../plan/SKILL.md`). If a path cannot be resolved, find `skills/<name>/SKILL.md` inside the mgkit installation.

## 1. Stages

1. **Size.** Apply the size rule in `../plan/SKILL.md`. State the choice (`plan` or `plan-max`) with a one-line reason. If the request already names one, use it. If the change is tiny and clear enough to pass the fit check in `../quick/SKILL.md`, add one line saying `quick` would skip the plan. Do not wait for a reply here; the user can override in their next message. If the request names a ticket (a task note, board card or issue, by path, link or id), read `../land/references/tickets.md` and move it to in progress as it says.
2. **Plan.** Read `../plan/SKILL.md` or `../plan-max/SKILL.md` and follow it completely, including its questions round. If a roast file for this feature exists, use it. The stage ends with the plan path.
3. **Plan review.** Read `../plan-review/SKILL.md` and follow it on the plan path. It repeats passes on its own until one comes back clean.
4. **Checkpoint A: the user checks the plan.** Stop. Show the plan path, the review report and any open USER TASKs. Ask the user to read the plan and reply "go", or to request changes. Apply requested changes to the plan and ask again. Never continue without an explicit go.
5. **Execute.** Record the current commit hash (`git rev-parse HEAD`) as the base. Read `../execute-plan/SKILL.md` and follow it on the plan path.
   - Small plan: continue in this session.
   - Big plan: if this session runs under a goal or long-running mode, continue. Otherwise tell the user that starting a fresh long-running session with the kickoff line from `../plan-max/references/kickoff.md` is recommended, and continue here only if the user says so.
6. **Final review.** execute-plan ends with its final review: review-and-fix on the whole change from its base commit to `HEAD`, repeating passes until one comes back clean. Do not run another one here. If execute-plan stopped before finishing, there is no final review yet; report that at checkpoint B.
7. **Checkpoint B: the user reviews the code.** Stop. Report the plan path, the commit range (`<base>..HEAD`), the gate result, the review summary, and remaining USER TASKs and blockers. Do not push, merge or open pull requests. Add one line on what can follow the user's approval: `squash` (`../squash/SKILL.md`) tidies fix commits into the commits they fix, and `land` (`../land/SKILL.md`) merges a worktree branch into the primary checkout and cleans up.

## 2. Resuming

When invoked with a plan path that already exists, work out the stage and say which one you detected:

- No plan review has happened in this conversation: resume at stage 3.
- The user already said "go" and tasks or steps remain: resume at stage 5.
- Every task is done but `TODO.md` has no final review log line (or, for a single-file plan, no final review happened in this conversation): run execute-plan's final review (its section 5), then checkpoint B.

Ask for confirmation before continuing past a checkpoint that was not explicitly passed in this conversation.

## 3. Rules

- Never skip checkpoint A or checkpoint B, even if the user asked not to be asked anything. In that case keep the checkpoint message to three lines.
- Everything the sub-skills forbid stays forbidden here: pushing, committing plan files, editing outside the repository.
