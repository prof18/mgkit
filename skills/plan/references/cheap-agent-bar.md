# The cheap-agent bar

A plan passes only when an implementing agent that is cheaper and less capable than you can follow it without guessing. Check every item before presenting a plan; fix gaps instead of noting them.

1. **No open choices.** No "maybe", "consider", "could", "etc.", "and so on", "TBD", "as appropriate", or "if needed" without the condition spelled out. Every decision is either made or listed as a `USER TASK` or `BLOCKED` precondition.
2. **Exact locations.** Every file to create or edit is named by its path from the repository root. Every symbol to change is named.
3. **Constants table.** Every literal used in more than one place (names, versions, URLs, ports, limits, user-facing strings) appears once in a constants table and is referenced by its key.
4. **Verified facts.** APIs, CLI flags, library versions and file formats were checked against current documentation or the local toolchain while planning, and the plan cites the source (link or command). Anything that could not be verified is marked, and the plan verifies it in an early step.
5. **Test-first steps.** Each step that changes behaviour says which test to write first, where it lives, and the command that runs it.
6. **Acceptance per step.** Each step ends with a checkable acceptance line: a command and its expected result, or an observable behaviour.
7. **Commit-sized steps.** Each step is one coherent commit, and dependencies between steps are explicit.
8. **Gate named.** The exact commands that must pass before every commit (lint, typecheck, tests), as they exist in this repository.
9. **Out of scope listed.** What must not be done or touched.
10. **Forbidden actions listed.** Pushing, publishing, touching production, destructive git commands, editing outside the repository: whichever apply.
11. **Human steps marked.** Anything that needs credentials, devices, accounts, payments or visual judgement is a `USER TASK` and is never self-certified.
12. **Roast honoured.** If a roast file exists, every decision in it is reflected and no rejected option reappears.
13. **Repository conventions.** The plan follows the repository's own instruction files (AGENTS.md, CLAUDE.md, contributing docs) and existing code patterns, citing the files.
