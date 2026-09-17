---
name: plan-max
description: Write a detailed multi-file implementation plan for a big or complex feature or project, with an HTML index, one HTML file per milestone and a TODO.md progress tracker, so a cheaper agent can build it step by step under a long-running goal. Use when the user asks for a full plan, a detailed plan for a cheap agent, a plan with index and todo, names plan-max, or when the work is too big for plan. The skill checks the size first and recommends the single-file plan skill when the work is small.
---

# Plan Max

Turn a big feature or project into a plan folder that a cheaper, less capable agent can work through task by task, across many sessions, without making judgement calls.

## When to use: the size rule

Read the size rule in `../plan/SKILL.md` (relative to this skill's directory; if that path cannot be resolved, look for `skills/plan/SKILL.md` inside the mgkit installation). Use `plan-max` when the work fails any condition of that rule. If the request actually fits `plan`, say so and why, and ask whether to switch. Never switch silently.

## Workflow

1. **Inputs.** Read the request and anything it references. Look for a roast file: `plan/*-<slug>.roast.md`, or the newest `plan/*.roast.md` if a roast just finished in this conversation. If several could match, ask which one.
2. **Explore.** Read the repository's instruction files (AGENTS.md, CLAUDE.md, contributing docs), the relevant code, build files and tests. Find the real gate commands. Verify every external fact the plan will rely on (documentation, versions, CLI help, API shapes) and keep the sources. If you can start subagents, use them for broad exploration; otherwise explore yourself.
3. **Questions first.** Before writing files, ask every question whose answer changes the plan, in rounds, formatted as:

   ```
   ❓ **Q1 - <short title>**: <question, with options>

   ➡️ <recommended answer and one-sentence reason>
   ```

   Always include the proposed milestone breakdown (one line per milestone) as a question, and get agreement on it. Skip other questions only when a roast file already settles them. Wait for the answers.
4. **Write** the plan folder (below).
5. **Self-check.** Read `../plan/references/cheap-agent-bar.md` and make every file satisfy every item. Also check across files: ids in milestone files match `TODO.md`, constants are defined once in `00-conventions.html`, links between files work, and no task uses something a later task creates.
6. **Present** the folder path, a summary of 5 to 10 lines, the milestone list, open USER TASKs, and the next step: "Run `plan-review` on it, then start it with the kickoff line below." Then print the kickoff lines (see Kickoff).

## Output folder

- Create `plan/<YYYY-MM-DD>-<slug>/` at the repository root, unless the user's instructions specify another location. Use today's date and a slug of 2 to 5 lowercase ASCII words joined by hyphens.
- A repository can hold several plans. Never reuse or overwrite an existing folder; if the name is taken, ask for a different slug.
- Create `plan/` if it does not exist. Do not add it to any ignore file. Do not commit the plan.

## Files

| File | From template | Contents |
|---|---|---|
| `INDEX.html` | `templates/INDEX.html` | Summary, "How to work this plan", milestone table, target layout, out of scope |
| `00-conventions.html` | `templates/00-conventions.html` | Working protocol, gate, constants, repository conventions |
| `NN-<topic>.html` | `templates/topic.html` | One per milestone, numbered `01`, `02`, … in execution order |
| `TODO.md` | `templates/TODO.md` | Every task, in order, with ids `T<milestone>.<n>` matching the milestone files |
| `LOCAL.md` | `templates/LOCAL.md` | Only when machine-specific values are needed (paths, device ids, where env files live). Never secrets, only where to find them |

For every HTML file: replace `{{head}}` with the full contents of `../plan/templates/_head.html`, fill every other `{{placeholder}}`, repeat blocks as needed, and HTML-escape code samples (`<` as `&lt;`, `>` as `&gt;`, `&` as `&amp;`). When done, searching the folder for `{{` must find nothing.

## Writing milestones and tasks

- A milestone is a coherent outcome with its own acceptance checks. Order milestones so each one only needs what earlier ones built. Put fact verification that could change later milestones first.
- A task is one commit. Each task in a milestone file lists: files, the test to write first, instructions, and an acceptance line. `TODO.md` repeats the task title and a short acceptance.
- End every milestone with a task `T<n>.<last> Milestone acceptance check`.
- Mark human-only work as `USER TASK` in both the milestone file and `TODO.md`.

## Kickoff

Read `references/kickoff.md` from this skill's directory. Print the big-plan kickoff line for the harness you are running in, with the real folder path filled in, then list the lines for the other harnesses below it.
