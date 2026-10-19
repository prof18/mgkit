---
name: plan-to-docs
description: "Turn finished implementation plans into present-tense docs that describe how the project works today, then retire the plans. Reads the code as the source of truth, with the plans, deviation logs, agent instructions, git history and the user's decision records as context; writes or updates focused pages under docs/, records decisions that live only in the plans, points AGENTS.md at the docs, fixes every link to the old plans and deletes them once the user agrees. Use when a plan is done and should become documentation: plan to docs, turn the plan into docs, retire the plans, clean up old plans, document what we built."
---

<!-- Adapted from https://github.com/chrisbanes/skills (skills/grounded-writing/SKILL.md and references/style-profile.md, commit 00bda528b7a13fb6ba475b0d50e50589aa5d274f), Apache License 2.0, Copyright (c) Chris Banes. See THIRD_PARTY_NOTICES.md. -->
<!-- Adapted from https://github.com/mattpocock/skills (skills/productivity/writing-for-agents/SKILL.md, commit b0618bc436ad893b3c5e84e55fba86586d34a404), MIT License, Copyright (c) 2026 Matt Pocock. See THIRD_PARTY_NOTICES.md. -->

# Plan to Docs

A finished plan describes what someone intended to build. The code describes what was built. Left in the repository, the plan drifts away from the code and keeps reading as instructions, so the next agent follows a spec that is no longer true. This skill moves everything that is still true into docs that describe the project as it is, records the decisions, and removes the plan.

The outcome: a `docs/` folder of present-tense pages, each linked from the project's agent instructions, plus plans that exist only while they are being built.

## 1. Find the plans

- If the user named plans or a folder, use those. Otherwise look under `plan/`, any plan location the user's instructions define, and folders such as `docs/plan/` that hold a build plan. Include the companion files: `TODO.md`, progress logs, deviation logs, roast files.
- Classify each plan:
  - **Finished**: every box in its `TODO.md` is ticked, or the user says it is done. A single-file plan without a `TODO.md` counts as finished when the user says so or when git history shows its tasks landed.
  - **Active**: unchecked tasks remain. Leave active plans alone unless the user includes them; say which ones you skipped.
- If there is no finished plan, say so, say where you looked, and stop without changing anything.
- Report the list of finished plans before writing anything.

## 2. Gather the sources

Read widely before writing a line. In order of authority:

1. **The code** is the source of truth for what the project does: modules, entry points, schema and migrations, schedulers, scripts, build files, manifests, resources.
2. **The project's agent instructions** (`AGENTS.md`, `CLAUDE.md` and the files they import), existing docs, and the README.
3. **Decision records** the user's instructions point to: a knowledge base, an ADR folder, a decisions page. Search them by topic; they hold the *why* that the code does not.
4. **The plans and their logs**: specs, decision sections, deviation logs, progress logs. They supply context and reasons, never facts about the current behaviour.
5. **Git history** (`git log`, `git log -S`) to date things and to see which planned work actually landed.

Where a plan and the code disagree, the code wins. Keep a list of every disagreement: features the plan promised that were never built, rules the code reversed, numbers that changed. You report them in step 7, because some may also be promised in public copy (a store listing, a privacy policy, a README).

## 3. Design the docs map

- Group what you learned by area a reader would look for: how the code is organized, how data flows and syncs, the UI, release and operations, external API notes. Fit the project; a small project may need one page.
- Name each page for what it covers, in lowercase kebab-case (`docs/architecture.md`, `docs/data-and-sync.md`). Never name a page after the plan, a milestone or a date.
- Extend an existing doc instead of adding a parallel one. Keep reference material that is still accurate (an API reference, a data-coverage matrix); move it out of the plan folder and fix its stale passages.
- Show the user the map: each page, what it covers, and which plan files it replaces. Continue unless they object.

## 4. Write each page from the code

Read `references/writing-docs.md` (relative to this skill's directory) before the first page, and follow it.

- Write in the present tense about what exists. No history narratives, no milestone IDs, no "we decided in M3".
- Check every claim against the code before keeping it: open the file, find the constant, read the query. Copy numbers (intervals, limits, retention windows) from the code, not from the plan. If a claim cannot be verified, leave it out or mark it as unverified.
- Link to the code instead of restating it. Point at the versions catalog, the schema folder, the script; restate a value only when it defines behaviour a reader needs to understand.
- Keep the *why* short and next to the *what*. A decision with a longer story belongs in the decision records (step 5); the page links or names it.
- Cross-link the pages. Every page states in its first lines what it covers and where the neighbouring topics live.

## 5. Record decisions that live only in the plans

Go through the plans, decision sections and deviation logs. For each decision or rule that is still true:

- Already in the code and the new docs: nothing to do.
- A product or design decision with a reason: record it where the user's instructions keep decisions (knowledge base, ADRs). If the project has no such place, add a short `docs/decisions.md` with one entry per decision: the rule, then the reason.
- A working rule for agents: it belongs in the agent instructions (step 6).
- No longer true: drop it, and note it if it contradicts something public.

## 6. Point everything at the docs

- Update the project's agent instructions (`AGENTS.md`, or `CLAUDE.md` when that is the only one) with a short table of the docs: one row per page, the page link and what it covers, worded so an agent knows when to open it. Replace any rule that sent agents to the old plan.
- Add the lifecycle rule if it is missing: a plan exists while it is being built; its last task updates the `docs/` pages its feature changed and records new decisions; then the plan is deleted.
- Search the whole repository for references to the plan files and folders (paths, file names, section names) and fix each one: the README, other docs, skills, code comments, test comments, scripts, ignore files.

## 7. Retire the plans

- Show the user what you are about to delete and the doc that now covers each file. Delete after they agree, unless their request already asked you to delete the plans.
- Delete tracked plan files with `git rm`; delete local, untracked plan folders from the filesystem. Leave active plans and anything you did not create or list.
- Report the disagreements from step 2, separating the ones that need a decision (a promised feature that was never built, public copy that is now wrong) from the ones the docs already absorbed.

## 8. Verify and commit

- Every repository path a doc names exists; every relative link resolves; a search for the old plan paths finds nothing outside the deleted files.
- Run the project's gate when you touched code, comments in source files, or anything a check reads; instruction and doc edits alone need only the checks that cover them.
- Commit the docs, instruction updates, link fixes and deletions with a message that says what the docs now cover. Stage explicit paths only; never stage a `plan/` folder. Do not push unless the user asks.

## Finish gate

Stop only when all of these are true:

- Each finished plan's still-true content lives in a doc, a decision record or the agent instructions, and nothing is lost that the code does not show.
- Every doc claim was checked against the code, and every number in the docs matches the code.
- The agent instructions link every doc, and no file in the repository points at a removed plan.
- The user has seen the list of disagreements between the plans and the code.
