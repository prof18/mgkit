---
name: explain-commit
description: Explain a Git commit, commit range, PR, or working diff through a code-grounded visual walkthrough with before/after diagrams, concrete scenarios, and source links. Use when the user wants to understand how a change works or review its architecture graphically.
---

# Explain a commit visually

Help the user read and understand the actual code. Default to a polished, standalone
local HTML walkthrough plus a short chat handoff. For a small follow-up question,
use an inline diagram or update the existing walkthrough instead of generating
another full report. Respect an explicitly requested format.

## Establish what is being explained

- Resolve the repository and requested commit, range, PR, or working diff. Use the
  conversation's active review target when clear; ask only if the target is ambiguous.
- Read repository instructions and relevant recorded preferences. Inspect status
  without disturbing local edits. Explaining changes does not imply permission to
  change code, commit, rebase, push, or publish anything.
- Record the exact target and comparison base hashes. For one commit, compare its
  parent; for a range, state its boundaries; for a PR, identify the actual base.
  For a merge commit, state which parent is being compared.
- Read the diff and surrounding implementation at the requested revision with Git.
  Trace callers, dependencies, persistence/schema, and relevant tests as needed.
  Do not explain an old commit using HEAD's implementation. If later commits matter,
  show a clearly labeled “At this commit / Current code” comparison. Never silently
  attribute a later fix to the earlier commit.

## Build the explanation around behavior

Lead with the concrete problem, the trigger, and what changes for the user or caller.
Develop one realistic example through the before and after paths. Name participants
clearly: `device1` and `device2`, or meaningful domain roles, instead of A and B.

Explain the parts that matter to this change, rather than filling a fixed template:

- Entry point → decisions → state changes → external effects → completion.
- Which component owns each state, which data is persisted, and which is temporary.
- Distinct paths that are easy to confuse: refresh/upload, capture/apply, local/cloud,
  request/acknowledgment, normal execution/retry. Keep them visually distinguishable.
- Terms such as revision, generation, session, snapshot, or pending changes: what
  each represents, who creates or increments it, when it is checked or cleared,
  and whether it belongs to a local database or an external provider.
- Why a mechanism exists: the concrete failure it prevents, its cost, and the
  consequence of removing it. If code is only forwarding calls, say so. Do not
  rationalize accidental complexity or claim every guard is indispensable.
- Main success path and the relevant failure/retry/interruption paths. Explain
  what remains saved after failure and what the next attempt does. Do not invent
  an exhaustive corner-case audit or broaden into unrelated providers/features.
- Extra work introduced by the change: queries, copies, downloads/uploads, locks,
  or background work. Count operations for a concrete scenario when code supports
  it; distinguish logical calls, actual network transfers, and measured performance.
- Tests that exercise the mechanism, what they assert, and what their fakes cannot
  prove. Distinguish reading a test from running it; do not run a full build solely
  to produce an explanation unless runtime evidence is needed or requested.

Separate observed behavior, reasoned interpretation, known limitations, and proposed
improvements. Use small real code excerpts only when they clarify a decision.

## Design visuals that support code review

Choose the visual form by the question:

| Question | Useful visual |
| --- | --- |
| What changed? | Before/after flow with the changed steps highlighted |
| Who calls whom, and when? | Sequence diagram with async boundaries and returns |
| Where does data go? | Data-flow diagram with explicit storage ownership |
| What survives failure or retries? | State diagram or event timeline |
| Why keep multiple counters or stores? | Small comparison table plus a worked example |
| How much work or time is involved? | Count comparison or measured plot with units |

Use a small overview with linked detail diagrams for complex changes. Avoid a single
unreadable graph. Each important node should show a plain-language action and the
exact symbol plus file path that implements it. Number steps consistently between
the diagram, example, and code-reading guide. Label arrows with the transferred data
or action. Make provider/platform differences explicit when they affect behavior.

Use plots only for real measurements or explicitly labeled illustrative values;
never manufacture timings or imply synthetic values are benchmarks. For exportable
scientific/performance plots, use standard plotting tools and include the data source.
Interactive step selection, before/after toggles, or scenario switching are useful
when they reduce reading effort; do not add decorative motion or needless controls.

## Produce the local artifact

Use a user-specified output location, otherwise the environment's local visualization
folder or an existing project documentation destination. Keep generated reports out
of the repository by default. A recap is not automatically an implementation plan.
Do not publish, upload, or create a share link unless explicitly requested.

Author self-contained HTML with inline SVG/CSS and only the JavaScript needed for
interaction. Use clear typography, a restrained palette, ample diagram spacing,
and readable code labels. Use responsive layout, semantic headings, keyboard-operable
controls, and labels in addition to color. Avoid network dependencies for fonts or
rendering. Long walkthroughs may scroll normally; never hide content to fit a screen.

If the installed `archify` skill would help with an elaborate diagram, read and use
its guidance for that diagram. It is optional: plain inline SVG or Mermaid rendered
to SVG works for compact diagrams. Do not require another skill to be installed.

Include a code-reading guide mapping steps to symbols and verified line locations.
Use absolute local file links in chat. In HTML, use local file URLs or an available
editor link mechanism, and retain copyable paths when navigation is blocked by the
viewer. Do not invent navigation URL formats. For historical code, prefer verified
permalink URLs when available or clearly labeled local excerpts exported with the
report. Do not link to HEAD's line numbers as if they showed a historical revision.
Escape repository text before inserting it into HTML, attributes, or JavaScript.

## Check and hand off

- Recheck diagram edges, branches, state ownership, and counts against the code.
- Verify source references, hashes, test names, and before/after attribution.
- Open the actual HTML with an available local browser/preview tool. Check a normal
  laptop viewport and a wider desktop viewport for overlap, clipping, legible labels,
  and working interactions. Inspect rendered output, not just source markup. If
  browser inspection is unavailable, report that limitation without claiming it passed.
- Finish with the local report link, a brief explanation of what it covers, and any
  material uncertainty. Open the report in the app's preview when available and useful.
  State which tests were actually run only if relevant; do not imply code was changed.

Example requests:

- “Use $explain-commit for this commit; show the before/after path and code locations.”
- “Use $explain-commit for this range, including retries and why these counters exist.”
- “Use $explain-commit to compare this PR with current code, using a visual walkthrough.”
