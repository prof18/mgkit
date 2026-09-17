# Kickoff lines for execute-plan

Replace `<path>` with the plan's real path. Big plans are folders (`plan/<date>-<slug>/`); small plans are single files (`plan/<date>-<slug>.html`).

| Harness | Small plan | Big plan |
|---|---|---|
| Claude Code | `/mgkit:execute-plan <path>` | `/goal Use the mgkit execute-plan skill on <path> until every task in TODO.md that is not a USER TASK is checked or blocked.` |
| Codex | `$execute-plan <path>` | `/goal Use $execute-plan on <path> until every task in TODO.md that is not a USER TASK is checked or blocked.` |
| OpenCode | `Use the execute-plan skill on <path>` | `Use the execute-plan skill on <path>` |
| Pi | `/skill:execute-plan <path>` | `/skill:execute-plan <path>` |

Notes:

- Claude Code and Codex have a native `/goal` mode that keeps the session working until the condition holds.
- OpenCode and Pi have no goal mode. `execute-plan` keeps looping through `TODO.md` by itself; if the session ends early, run the same line again to continue.
- Codex: if your Codex version lists plugin skills with a prefix (for example `$mgkit:execute-plan`), use that form.
