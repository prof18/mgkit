---
name: plan-review
description: Review an implementation plan, either a single-file plan or a multi-file plan folder, in one thorough pass and fix it in place. Checks consistency, security, performance, missing pieces, dark paths, anything a cheaper implementing agent could misread, API and tooling facts against current docs, and conformance to the roast decisions. Uses a panel of the other installed agent CLIs (Claude Code, Codex, Pi) for up to 3 rounds when available. Use when the user asks to review, validate, double-check or harden a plan, or before executing one.
---

# Plan Review

Make a plan safe to hand to a cheaper agent: find what is wrong, missing or ambiguous, fix it in the plan, and report. One pass per invocation.

## 1. Target

- The argument is a path: an `.html` file (small plan) or a folder containing `TODO.md` (big plan). Without an argument, list the plans under `plan/` newest first (files and folders) and ask which one.
- Read all of it. For a folder, read every file, including `TODO.md` and `LOCAL.md`. Read the matching roast file (`plan/*-<slug>.roast.md`) if one exists.
- Read the repository's instruction files and the code the plan touches, enough to judge whether the plan fits reality.
- If the plan is partly executed (ticked boxes in `TODO.md`, or commits that implement its steps), review only what is not executed yet. Never rewrite executed steps; report any conflict with executed work as a finding for the user.

## 2. One pass through these lenses

| Lens | Look for |
|---|---|
| Consistency | Constants that differ between files; task ids in milestone files versus `TODO.md`; paths that don't match the target layout; decisions contradicted later; broken links between plan files. |
| Completeness | Missing steps (setup, migrations, cleanup, docs, changelog, release), missing tests, missing error handling, missing acceptance lines, undefined terms. |
| Cheap-agent risk | Every item in `../plan/references/cheap-agent-bar.md` (relative to this skill's directory; if unresolvable, find `skills/plan/references/cheap-agent-bar.md` in the mgkit installation). Also: steps that use something created later, vague verbs ("handle", "support", "improve"), steps too big for one commit, instructions that need taste. |
| Facts | Check APIs, CLI flags, library versions, file formats and platform limits against current documentation or local tool help. Search the web. Keep the source for every correction. |
| Security | Secret handling, injection, authentication and permissions, unsafe defaults, new dependencies, sensitive data in logs. |
| Performance | Hot paths, unbounded work, N+1 patterns, large payloads, missing caching or pagination where the plan implies scale. |
| Dark paths | Offline, empty, error, retry and backoff for flaky services, partial failure, concurrency, cancellation, upgrades from existing data. |
| Roast conformance | Every roast decision is reflected; no rejected option appears; open questions are resolved or turned into USER TASKs or verification steps. |
| User focus | If the user named a focus ("API resilience", "security"), go deeper on it in addition to the lenses above. |

Always do the whole pass yourself. Also read `../review-and-fix/references/panel.md` (relative to this skill's directory; if unresolvable, find `skills/review-and-fix/references/panel.md` in the mgkit installation) and check seat availability. With at least one other seat available, run panel round 1 on the plan while you do your pass, with the lenses above as the task and the plan path as the target. Keep the panel files and findings in the session scratch directory; plan reviews never use Difftray. Without a panel, if you can start subagents, you may split the lenses across at most 3 reviewers, each with a self-contained prompt; you merge, verify and decide.

## 3. Grade and fix

- Give every finding a severity (critical, high, medium, low), an evidence-based confidence (high: traced or verified; medium: traced with a stated assumption; low: speculation), its lens, and its location (file plus section or task id).
- Discard low-confidence findings.
- Fix in place every remaining finding that has one correct fix consistent with the plan's decisions. Keep structure and ids stable. If a task must be split, use sub-ids (`T3.2a`, `T3.2b`) and update `TODO.md` to match.
- With a panel: take the round-1 plan snapshot before your first edit, then run rounds 2 and 3 as `panel.md` describes; its "Snapshots" part says how to show the plan changes since the last round. Objections you accept and new critical or high findings are graded and fixed like the others.
- A finding that needs a decision the plan has not made, and every objection still open when the panel stops, goes to the user as a question:

  ```
  ❓ **Q1 - <short title>**: <question, with options>

  ➡️ <recommended answer and one-sentence reason>
  ```

  Apply the answers, then finish.
- Keep HTML code samples escaped. Do not commit plan files.

## 4. Report

```
## Plan review — <path>
Fixed: <n> · Needs decision: <n> · Discarded: <n>
<panel lines from section 5 of panel.md, when a panel ran>

| # | Severity | Lens | Where | Finding | Action |
|---|---|---|---|---|---|

Sources checked: <links or commands>
```

End with: "One pass done. Run plan-review again for another pass." Never start a second pass on your own.
