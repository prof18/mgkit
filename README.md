# mgkit

An opinionated toolkit for building software with AI agents. Roast the idea, plan it so a cheap agent can build it, execute, review, ship. Works in Claude Code, Codex, OpenCode and Pi.

## Why

mgkit encodes one way of working, and it is opinionated on purpose:

- **Talk before building.** Ideas get roasted and every decision is settled before a plan exists.
- **Plans are written for cheaper agents.** A strong model plans; a cheaper one implements without having to make judgement calls.
- **Plans are HTML; progress is a `TODO.md`.** Easy to read for humans, easy to follow for agents, one source of truth for progress.
- **Test first.** Behaviour changes start with a failing test.
- **Review before commit.** Every commit goes through a graded review-and-fix pass.
- **Your repository stays yours.** Skills stage explicit paths only, never commit plans, and never push unless you ask.

## Pipeline

```
roast ──▶ plan / plan-max ──▶ plan-review ──▶ [you check the plan] ──▶ execute-plan ──▶ review-and-fix ──▶ [you review the code]
          └───────────────────────────────── build runs all of this end to end ─────────────────────────────────┘
```

## Skills

| Skill | What it does | Use it when |
|---|---|---|
| `roast` | Critiques an idea, questions you in rounds until every decision is settled, hunts for a name, writes a roast file | You are about to start something new or want your requirements challenged |
| `plan` | Writes a small feature plan as one standalone HTML file | The change is small and contained |
| `plan-max` | Writes a plan folder: HTML index, one file per milestone, `TODO.md` | The work is big, multi-part, or spans sessions |
| `plan-review` | Reviews a plan in one pass and fixes it in place | Before executing any plan |
| `execute-plan` | Implements a small plan in one run, or a big plan task by task from `TODO.md` | A reviewed plan is ready |
| `review-and-fix` | One bounded review pass: grade findings, fix only confirmed ones | Before a commit, a merge, or after a large change |
| `build` | Runs plan, plan-review, execute-plan and review-and-fix, stopping twice for you | You want a feature taken end to end |
| `explain-commit` | Visual walkthrough of a commit, range, PR or diff | You need to understand a change |
| `worktree-task` | Does a task in an isolated Git worktree, merges it back, cleans up | You want work isolated from your checkout |
| `renovate-update-loop` | Processes Renovate update PRs locally, one by one, with full validation | Dependency updates piled up |
| `renovate-pr-pass` | Merges green Renovate PRs and triggers rebases for blocked ones | Quick pass over Renovate PRs on GitHub |

## Install

Full details, local-checkout installs and isolated checks: [docs/harnesses.md](docs/harnesses.md).

**Claude Code**

```
/plugin marketplace add <owner>/mgkit
/plugin install mgkit@mgkit
```

Skills are invoked as `/mgkit:<skill>`.

**Codex**

```
codex plugin marketplace add <owner>/mgkit
codex plugin add mgkit@mgkit
```

Mention skills with `$<skill>`.

**OpenCode** — add to `opencode.json` and restart:

```json
{ "plugin": ["mgkit@git+https://github.com/<owner>/mgkit.git"] }
```

Ask for a skill by name ("use the execute-plan skill on …").

**Pi**

```
pi install git:github.com/<owner>/mgkit
```

Skills are invoked as `/skill:<skill>`.

**Other tools** — `npx skills add <owner>/mgkit`, or copy `skills/` into your tool's skills directory.

## Plans

- Small plans: `plan/<YYYY-MM-DD>-<slug>.html`. Big plans: `plan/<YYYY-MM-DD>-<slug>/`. Roast decisions: `plan/<YYYY-MM-DD>-<slug>.roast.md`. A repository can hold many plans.
- Plans are never committed, and mgkit never edits your ignore files.
- Want plans somewhere else? Say so in your own `AGENTS.md` or `CLAUDE.md`; the skills treat these locations as defaults.

## Credits

The question rounds in `roast` are adapted from the `grilling` skill in [mattpocock/skills](https://github.com/mattpocock/skills) (MIT). See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## Status

0.0.x: a personal toolkit, used daily, expect changes.

## License

MIT. Includes adapted third-party material, see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
