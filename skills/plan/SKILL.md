---
name: plan
description: Write a small, precise implementation plan as a single standalone HTML file that a cheaper agent can execute without guessing. Use for small, contained features or fixes, when the user asks to plan a small feature, write a quick plan, or plan this change. For big or multi-part work use plan-max instead.
---

# Plan

Turn a small feature or fix into one HTML file that a cheaper, less capable agent can implement step by step without making a single judgement call.

## When to use: the size rule

Use `plan` when **all** of these are true; otherwise use `plan-max`:

- At most 10 steps, each one commit.
- The change touches one area of the codebase, or a few files across areas for a small cross-cutting change.
- No new external integration (API, SDK, service, platform capability) and no new persisted data format or migration.
- One agent session can implement it.

If the request does not fit, say that `plan-max` fits better and why, and ask whether to switch. Never switch silently.

## Workflow

1. **Inputs.** Read the request and anything it references. Look for a roast file for this feature: `plan/*-<slug>.roast.md`, or the newest `plan/*.roast.md` if a roast just finished in this conversation. If several could match, ask which one.
2. **Explore.** Read the repository's instruction files (AGENTS.md, CLAUDE.md, contributing docs), the code involved, build files and existing tests. Find the real gate commands. Verify external facts (docs, versions, CLI help). If you can start subagents, use them for broad exploration; otherwise explore yourself.
3. **Questions first.** Before writing anything, ask every question whose answer changes the plan, in rounds, formatted as:

   ```
   ❓ **Q1 - <short title>**: <question, with options>

   ➡️ <recommended answer and one-sentence reason>
   ```

   Skip this when a roast file already settles everything. Wait for the answers.
4. **Write** the plan (below).
5. **Self-check.** Read `references/cheap-agent-bar.md` from this skill's directory and make the plan satisfy every item. Fix gaps before presenting.
6. **Present** the path, a summary of 5 to 10 lines, any open USER TASKs, and the next step: "Run `plan-review` on it, then `execute-plan`."

## Output

- Save the plan to `plan/<YYYY-MM-DD>-<slug>.html` at the repository root, unless the user's instructions specify another location. Use today's date and a slug of 2 to 5 lowercase ASCII words joined by hyphens. Never overwrite an existing plan; pick a different slug.
- Create `plan/` if it does not exist. Do not add it to any ignore file. Do not commit the plan.
- Start from `templates/plan.html`. Replace `{{head}}` with the full contents of `templates/_head.html`. Fill every other `{{placeholder}}`, repeat blocks (context items, decisions, constants, steps) as needed, and delete a section only when it would be empty (Constants may be omitted when there are none).
- HTML-escape every code sample (`<` as `&lt;`, `>` as `&gt;`, `&` as `&amp;`).
- Before presenting, confirm no placeholder is left: searching the file for `{{` must find nothing.
