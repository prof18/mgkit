---
name: review-and-fix
description: "Run a budget-conscious, agent-assisted codebase review and remediation pass. Use when the user asks to review and fix, run a code review pass, or review a whole repository, branch, PR, or large change set for bugs, performance issues, accessibility problems, build/release risks, or general quality problems; to split review work across subagents; to grade, filter, and fix validated findings; or to run another review pass. Defaults: one review pass with 1-3 mid-tier reviewer subagents, main-agent verification and grading, a single fix worker, then stop. Further passes run only when the user asks, and reuse the session findings ledger."
---

# Review and Fix

Turn a broad "review everything and fix what matters" request into one bounded review/grade/fix pass. The goal is a short list of concrete, verified, important defects that get fixed, not a giant speculative audit. Low-confidence and unimportant findings are filtered out before any fix work starts.

The user starts additional passes explicitly. Each pass reuses the session findings ledger so it spends its budget on new ground.

## Agent Budget

Subagents are expensive. Spawn only the agents a step actually needs.

- **Reviewers:** 1 for a small repo or diff, 2-3 for large codebases, split by real domain boundaries. Hard cap 3 unless the user asks for more.
- **Reviewer model:** mid-tier. Reviewers optimize for recall; the main agent provides precision.
- **Verification:** done by the main agent. Spawn one verifier agent for the whole batch only when merged findings exceed ~10. Never spawn one verifier per finding.
- **Fix workers:** 1 on a mid or small model. Use 2 only when fixes touch fully disjoint modules. The main agent makes trivial one-line fixes directly.
- **No default second pass**, full or narrow. Fix correctness is covered by the main agent's diff review plus tests and gate.
- Launch every subagent with fresh context (no inherited conversation, e.g. `fork_turns="none"`) and a self-contained prompt.
- If subagents are unavailable, say so briefly and run the same steps locally.

Typical total: 2-4 subagents per pass.

## Ground Rules

- Read repo instructions first: `AGENTS.md`, `CLAUDE.md`, project docs, local rule files, relevant plans.
- Inspect the real current worktree before judging anything. Do not rely on stale notes.
- Prefer root-cause fixes with focused regression tests over broad refactors.
- Keep unrelated dirty worktree changes untouched.
- Preserve the starting commit posture. If the reviewed work starts committed with nothing uncommitted in scope, commit the fix batch. If the task is reviewing uncommitted changes, do not commit unless the user explicitly asks.
- Do not push just to review. Push only when the user requested push, PR update, release, or publication.
- Report blockers precisely: missing credentials, unavailable devices, policy-denied tools.

## Findings Ledger

Keep one ledger per review target for the current session, in the agent's session scratch/temp directory. Never write it into the repository or `.git/`. It does not need to survive the session.

One line per merged finding:

```
F1  fixed      SyncRepo.kt:120   correctness/high   race when two refreshes overlap   (commit abc123)
F2  rejected   FeedParser.kt:88  correctness/-      "null crash": value validated upstream in FeedLoader
F3  follow-up  SettingsScreen    accessibility/low  missing content description on refresh icon
F4  discarded  Utils.kt:40       performance/-      low confidence: pattern match, no hot path shown
F5  escalate   Db schema         correctness/high   needs migration decision from user
```

Statuses: `fixed`, `rejected` (verified false), `discarded` (low confidence or below threshold), `follow-up` (real but not fixed), `escalate` (needs a user decision).

When the user asks for another pass in the same session, pass the ledger to reviewers as the skip list. A finding matching a `rejected` or `discarded` entry is dropped without re-verification unless the code changed. A finding matching a `fixed` entry is a regression and gets priority.

## Grading Rubric

Every finding carries three grades. Reviewers propose them; the main agent sets the final values.

**Confidence** is evidence-based, not a gut number:
- **high:** full code path traced to the failure, or a failing test/repro exists.
- **medium:** code path traced, but the failure depends on a stated runtime assumption.
- **low:** pattern match, "could be", or speculation without a traced path. **Always discarded.**

**Severity:**
- **critical:** data loss, crash, concrete security exposure, broken install/upgrade, release blocker.
- **high:** user-visible incorrect behavior, meaningful performance regression, accessibility failure on a primary flow.
- **medium:** incorrect behavior in a real but secondary path, stale automation, fragile code with a concrete trigger.
- **low:** minor polish, unlikely edge case, cleanup.

**Category:** correctness, concurrency, performance, security, accessibility, build/release, tests.

**Verdict** (main agent only): `CONFIRMED` (traced and real), `PLAUSIBLE` (likely but not fully proven), `REJECTED` (false, stale, or already handled).

## Gate

| Verdict | Severity | Outcome |
|---|---|---|
| CONFIRMED | critical / high / medium | fix (subject to Scope Governor) |
| CONFIRMED | low | `follow-up`, not fixed |
| PLAUSIBLE | critical / high | main agent digs until CONFIRMED or REJECTED; if still unresolved, `escalate` |
| PLAUSIBLE | medium / low | `discarded` |
| any | confidence low | `discarded` |
| REJECTED | any | `rejected` with a one-line reason |

## Scope Governor

Before reviewing, freeze a baseline:

- user request and target
- branch/worktree, dirty/staged/committed starting state, derived commit policy
- intended behavior or release target
- owner boundaries and high-risk surfaces
- reviewer shard map and agent budget for this pass
- skip list (ledger from earlier passes in this session, known repeats)

A gate-passing finding is further classified:

- **In-scope blocker:** fix it.
- **Follow-up:** real issue outside the owner boundary, broad hardening, product/content gap. Ledger as `follow-up`.
- **Stop-and-escalate:** needs a new public contract, migration, release-process policy, architecture direction, storage/protocol change, or user decision. Ledger as `escalate`.

Pause and reclassify when a narrow fix turns into an architecture or process rewrite, the diff grows well beyond the task, or the right fix is to define a canonical contract first. Critical exceptions: active data loss, crash, broken install/upgrade, concrete security exposure, release blockers.

## Target Selection

- **Dirty local work:** review only actual unstaged/staged/untracked changes.
- **Branch or PR:** review against the real base branch or PR base.
- **Committed stack:** review recent commits individually or as a range.
- **Whole codebase audit:** review current source by domain slices, not only a diff.

A clean worktree is not proof of a clean codebase.

## Release Branch Discipline

On release, beta, hotfix, signing, notarization, packaging, or store-submission work:

- Fix only release blockers, failed release infrastructure, exact backports, install/upgrade breakage, data loss, crashes, or concrete security exposure.
- Treat everything else as `follow-up` for the development branch.
- Do not add product behavior, storage/protocol shape, config surface, or process policy unless it directly unblocks the release.
- Tie proof to the release target: branch/ref, failing check, shipped-risk reason, forward-port need.

## Workflow

1. **Baseline.**
   - `git status --short`; read project instructions and test/build entry points.
   - Freeze the Scope Governor baseline and create or load the session ledger.
   - Choose the reviewer count and shard map within the Agent Budget.

2. **Review.**
   - Launch 1-3 read-only reviewers in parallel with the Reviewer Prompt below.
   - While they run, inspect the highest-risk code paths yourself instead of waiting idle.

3. **Merge.**
   - Collect all findings, including your own. Dedupe by root cause, not by file:line.
   - Drop anything matching `rejected`/`discarded` ledger entries for unchanged code.
   - Findings reported independently by two reviewers get confidence raised one level.

4. **Verify and grade** (main agent; one batch verifier only if >10 findings).
   - For each finding, try to disprove it: trace the real code path, read callers, adjacent files, tests, schemas, generated code, dependency source/docs.
   - Reject speculative risks, unrealistic edge cases, and fixes more complex than the bug warrants.
   - For security, require a concrete actionable risk or a removed safety check.
   - Assign final verdict, confidence, severity, category. Apply the Gate and Scope Governor.
   - For each accepted bug class, check sibling surfaces in scope now so siblings join the same fix batch.
   - Write every outcome to the ledger.

5. **Fix.**
   - If nothing passed the gate, skip to step 7.
   - Send accepted findings to one fix worker (two only for disjoint modules) with the Worker Prompt. Do trivial fixes directly.
   - Workers add or update tests in the nearest existing test style.

6. **Review the fix diff and verify.**
   - The main agent reads the full worker diff: correct root cause, no incomplete fix, no unrelated edits. Look harder at fixes touching many files, concurrency, migrations, or storage.
   - Run focused tests, then the repo's required gate. If the gate needs an unavailable device/credential, run as far as possible and record the exact prerequisite.
   - Commit per the frozen commit policy, staging only intended files. Record the commit in the ledger.

7. **Report and stop.** Do not start another pass unless the user asks.

## Additional Passes (user-requested)

When the user asks for another pass:

- Re-baseline with `git status --short`.
- Reuse the session ledger as the skip list; tell reviewers to prioritize areas not already covered.
- Follow the same Agent Budget and Workflow.
- If the user asks for a "deep" or parallel review (e.g. two models on the same baseline), merge all reviewer output before verification.

## Long-Running Reviews

- Real review work can take many minutes; treat advancing progress as healthy.
- Inspect a quiet reviewer only after repeated missing heartbeats, an explicit failure, or the environment timeout.
- If a reviewer fails (sandbox, auth, rate limit, capacity), report it and continue with remaining evidence instead of inventing results.

## Reviewer Prompt

```text
Review pass for <repo path>. Focus only on <scope>. Read AGENTS.md / CLAUDE.md and relevant project rules first. Do not edit files.
Skip these already-handled findings: <ledger skip list>.
Report only concrete bugs, performance, security, accessibility, or build/release issues. Do not report style, naming, or speculative hardening.
For each finding return:
- location: file:line
- category: correctness | concurrency | performance | security | accessibility | build/release | tests
- severity: critical | high | medium | low
- confidence: high (full path traced or repro) | medium (traced, depends on stated runtime assumption) | low (pattern match / speculation)
- evidence: the traced code path or repro, in a few lines
- minimal fix
If you cannot trace a path for a suspicion, either mark it low confidence or leave it out. If nothing qualifies, say "none".
```

## Worker Prompt

```text
Implement these accepted fixes in <repo path>: <findings with file:line, evidence, and intended fix>.
You own only <files/modules>. You are not alone in the codebase; do not revert others' edits or touch unrelated code.
Fix the root cause, add focused tests in the nearest existing style, run the focused tests.
Report changed files, tests added, and commands run with results.
```

## Final Report

Keep it concise:

- Agents used (reviewers, verifier if any, workers).
- Findings funnel: reported -> merged -> fixed / follow-up / escalate / rejected / discarded (counts).
- Fixed findings, one line each, with commit or "left uncommitted".
- Follow-ups and escalations, one line each.
- Discarded and rejected findings as a collapsed one-line-each list.
- Gates run and results; unresolved blockers with exact prerequisite.
- Whether the worktree is clean.
