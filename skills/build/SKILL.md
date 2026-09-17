---
name: build
description: Run the full mgkit pipeline for a feature. Plans it, reviews the plan, stops for the user to check the plan, then executes it and runs review-and-fix, stopping at the end for the user's code review. Use when the user says build this, take this feature end to end, or run the whole pipeline.
---

# Build

Take one feature from request to reviewed commits by running the other mgkit skills in order. This skill adds no method of its own, only the sequence and two mandatory human checkpoints.

Every skill named below is read from this skill's directory by relative path (for example `../plan/SKILL.md`). If a path cannot be resolved, find `skills/<name>/SKILL.md` inside the mgkit installation.

## 1. Stages

1. **Size.** Apply the size rule in `../plan/SKILL.md`. State the choice (`plan` or `plan-max`) with a one-line reason. If the request already names one, use it. Do not wait for a reply here; the user can override in their next message.
2. **Plan.** Read `../plan/SKILL.md` or `../plan-max/SKILL.md` and follow it completely, including its questions round. If a roast file for this feature exists, use it. The stage ends with the plan path.
3. **Plan review.** Read `../plan-review/SKILL.md` and follow it on the plan path. One pass.
4. **Checkpoint A: the user checks the plan.** Stop. Show the plan path, the review report and any open USER TASKs. Ask the user to read the plan and reply "go", or to request changes. Apply requested changes to the plan and ask again. Never continue without an explicit go.
5. **Execute.** Record the current commit hash (`git rev-parse HEAD`) as the base. Read `../execute-plan/SKILL.md` and follow it on the plan path.
   - Small plan: continue in this session.
   - Big plan: if this session runs under a goal or long-running mode, continue. Otherwise tell the user that starting a fresh long-running session with the kickoff line from `../plan-max/references/kickoff.md` is recommended, and continue here only if the user says so.
6. **Final review.** Read `../review-and-fix/SKILL.md` and follow it on the whole change from the base commit to `HEAD`.
7. **Checkpoint B: the user reviews the code.** Stop. Report the plan path, the commit range (`<base>..HEAD`), the gate result, the review summary, and remaining USER TASKs and blockers. Do not push, merge or open pull requests.

## 2. Resuming

When invoked with a plan path that already exists, work out the stage and say which one you detected:

- No plan review has happened in this conversation: resume at stage 3.
- The user already said "go" and tasks or steps remain: resume at stage 5.
- Every task is done: resume at stage 6.

Ask for confirmation before continuing past a checkpoint that was not explicitly passed in this conversation.

## 3. Rules

- Never skip checkpoint A or checkpoint B, even if the user asked not to be asked anything. In that case keep the checkpoint message to three lines.
- Everything the sub-skills forbid stays forbidden here: pushing, committing plan files, editing outside the repository.
