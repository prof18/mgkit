# Harness support

mgkit ships one `skills/` folder plus a thin wrapper per harness.

| Harness | Tested version | Support level |
|---|---|---|
| Claude Code | 2.1.281 | tested before release |
| Codex CLI | 0.162.1 | tested before release |
| OpenCode | 2.0.29 (1.18.31 for the OpenCode 1 path) | tested before release |
| Pi | 1.2.0 | tested before release |
| Others (plain skills) | — | best effort |

Facts below were verified on 2026-09-17 with a throwaway fixture plugin, unless listed under "Pending manual verification". The install checks and the update commands were re-verified on 2026-10-19 with the versions in the table.

`scripts/install-check.sh [claude|codex|opencode|pi|all]` runs every isolated check below against this repository and prints `ok`/`FAIL` per harness.

## Claude Code

Wrapper: `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` (marketplace entry `"source": "./"`). Skills are discovered from the root `skills/` folder. A root `plugin.json` (the Codex manifest) next to them does not affect validation.

### Install (from GitHub, for users)

```
/plugin marketplace add prof18/mgkit
/plugin install mgkit@mgkit
```

### Install (local checkout, for development)

```
claude plugin marketplace add /path/to/mgkit
claude plugin install mgkit@mgkit
```

For a single session without installing: `claude --plugin-dir /path/to/mgkit`.

### Update

```
claude plugin marketplace update mgkit
claude plugin update mgkit@mgkit
```

The first command re-clones the marketplace; the second installs the new version into `~/.claude/plugins/cache/mgkit/mgkit/<version>/`. Restart Claude Code to load it. Inside a session, `/plugin` offers the same update.

### Invoke a skill

`/mgkit:<skill>`, e.g. `/mgkit:roast`. Verified: `claude --plugin-dir <fixture> -p "/fixture:hello-mgkit"` ran the skill.

### Long-running goal mode

`/goal <condition>` (used to run this very plan). The condition is free text; name the skill in it rather than nesting a slash command.

### Isolated check used by mgkit maintainers

- `claude plugin validate <root>` validates the marketplace manifest; `claude plugin validate <root>/.claude-plugin/plugin.json` validates the plugin manifest; `claude plugin validate <root>/skills` validates the skills. All three must pass.
- `claude --plugin-dir <root> plugin details mgkit` prints the skill inventory (`Skills (N)  name, …`) without a model call or config change.
- `claude --plugin-dir <root> -p "<prompt>"` loads the plugin for one run without changing any config.
- `claude plugin validate <root>/.claude-plugin/plugin.json` warns that the contributor `CLAUDE.md` at the root is not loaded as plugin context; that warning is expected.

## Codex

Wrapper: root `plugin.json` (portable Agent Plugins format) and `.agents/plugins/marketplace.json`.

Manifest decision: **root `plugin.json`** with `"$schema": "https://agent-plugins.org/schemas/1.0.0/plugin.schema.json"`. Evidence: with only a root `plugin.json` (no `.codex-plugin/`), `codex plugin add fixture@fixture` installed version `0.0.1` read from it and copied `skills/` into the plugin cache, both with and without `$schema`. The schema requires only `$schema` and `name`; allowed top-level keys are `$schema, author, description, extensions, homepage, keywords, license, name, repository, version`. `.codex-plugin/plugin.json` is only a documented compatibility fallback and is not used.

Marketplace source form that works for a plugin at the marketplace root: `{ "source": "local", "path": "./" }`.

### Install (from GitHub, for users)

```
codex plugin marketplace add prof18/mgkit
codex plugin add mgkit@mgkit
```

Start a new session afterwards.

### Install (local checkout, for development)

```
codex plugin marketplace add /path/to/mgkit
codex plugin add mgkit@mgkit
```

A local marketplace is recorded in `config.toml` with `source_type = "local"`. A local install copies the whole working tree into the plugin cache, untracked files included; reinstall (`codex plugin remove mgkit@mgkit` then `codex plugin add mgkit@mgkit`) to pick up changes.

### Update

```
codex plugin marketplace upgrade mgkit
codex plugin add mgkit@mgkit
```

`marketplace upgrade` refreshes the Git marketplace, and `codex plugin list` then reports the new version, but the plugin cache only gains `~/.codex/plugins/cache/mgkit/mgkit/<version>/` after `plugin add`. Start a new session afterwards.

### Invoke a skill

Type `$` to mention a skill (`$execute-plan`) or run `/skills` (Codex docs). Plugin skill namespacing in the `$` picker: see pending verification.

### Long-running goal mode

`/goal <condition>` (Goal Mode, documented as generally available since May 2026).

### Isolated check used by mgkit maintainers

Set `CODEX_HOME=$(mktemp -d)` for every command: `codex plugin marketplace add <root>`, `codex plugin list` (shows `mgkit@mgkit  not installed`), `codex plugin add mgkit@mgkit`, then confirm `$CODEX_HOME/plugins/cache/mgkit/mgkit/<version>/skills/<skill>/SKILL.md` exists for every skill. No login needed.

## OpenCode

Wrapper: `.opencode/plugins/mgkit.js`, referenced by `"main"` in `package.json`. One file serves both host generations: OpenCode 2 reads the default export's `id` and `setup()` and registers every `skills/<name>/SKILL.md` through the skill transform (id, name, and description come from the frontmatter); OpenCode 1 (1.18.29+) calls `server()`, whose `config` hook appends the absolute path of `skills/` to `config.skills.paths` (a documented config key: `skills.paths` is scanned recursively for `**/SKILL.md`). OpenCode 1 treats every export of a plugin module as a plugin: a module that also exported a helper function and a string loaded no skills at all, so the file exports only the default object.

### Install (from GitHub, for users)

Add to `opencode.json` (global `~/.config/opencode/opencode.json` or project) and restart OpenCode — OpenCode 2 also accepts the native plural key `plugins`:

```json
{ "plugin": ["mgkit@git+https://github.com/prof18/mgkit.git"] }
```

### Install (local checkout, for development)

Either spec works (both verified):

```json
{ "plugin": ["file:///path/to/mgkit/.opencode/plugins/mgkit.js"] }
```

```json
{ "plugin": ["mgkit@git+file:///path/to/mgkit"] }
```

The `git+file` form installs the committed state into the OpenCode cache (`~/.cache/opencode/packages/` on OpenCode 1, `~/.cache/opencode/npm/git-mgkit-<hash>/<timestamp>/node_modules/mgkit` on OpenCode 2); the `file://` form reads the working tree directly. On OpenCode 2, `opencode plugin add <spec>` installs a plugin and adds it to the global config in one step.

### Update

A Git spec is fetched again into a new timestamped folder in the cache; on OpenCode 2.0.29 the new release was picked up with no manual step. Restart OpenCode to load it. `opencode plugin update` covers npm package plugins only and reports "No package plugins found" for a Git spec.

### Invoke a skill

OpenCode loads skills through its native `skill` tool; ask for it by name ("use the execute-plan skill on …"). Skills are not slash commands.

### Long-running goal mode

None (`opencode --help` has no goal mode). `execute-plan` loops through `TODO.md` by itself.

### Isolated check used by mgkit maintainers

`scripts/install-check.sh opencode` picks the path from `opencode --version`. Neither needs a login, and neither touches the global `~/.config/opencode/opencode.json`.

- **OpenCode 2.** There is no model-free command that lists skills: `opencode debug skill` is gone, and `GET /api/skill` and `GET /api/plugin` on a `--standalone` server return empty lists before a session runs. Instead, point `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_STATE_HOME` and `XDG_CACHE_HOME` at a temp directory, run `opencode plugin add "mgkit@git+file://<root>"` (it installs the committed state, so commit first), then import the installed copy's `main` and call `setup()` with a stub `skill.transform`, the way OpenCode 2 registers skills, and check every skill was added.
- **OpenCode 1.** `OPENCODE_CONFIG_DIR=$(mktemp -d)` with an `opencode.json` containing the `file://` spec, plus `OPENCODE_DISABLE_EXTERNAL_SKILLS=1` so skills under `~/.claude` and `~/.agents` don't mix in; run `opencode debug skill` from a temp directory with its output redirected to a file (piped output is cut off at about 64 KB, which the full skill set exceeds) and check the JSON array (`jq -r '.[].name' file`) lists every skill.

## Pi

Wrapper: the `pi` key in `package.json`: `"pi": { "skills": ["./skills"] }`.

### Install (from GitHub, for users)

```
pi install git:github.com/prof18/mgkit
```

### Install (local checkout, for development)

```
pi install /path/to/mgkit          # global
pi install -l /path/to/mgkit       # project-local (.pi/settings.json)
```

### Update

```
pi update git:github.com/prof18/mgkit
```

Pulls the Git package in `~/.pi/agent/git/github.com/prof18/mgkit`; plain `pi update` updates every package. Restart Pi to load it.

### Invoke a skill

`/skill:<name>`, e.g. `/skill:execute-plan` (Pi README).

### Long-running goal mode

None built in (Pi README: sub-agents and plan modes are left to extensions). `execute-plan` loops through `TODO.md` by itself.

### Isolated check used by mgkit maintainers

In `$(mktemp -d)`: `pi install -l <root>` writes only `./.pi/settings.json`; `pi list -a` (the `-a` trusts project-local settings) prints the package under "Project packages". Plain `pi list` without `-a` prints "No packages installed." for project-local installs. The global `~/.pi/agent/settings.json` is not touched.

## Other tools

`npx skills add prof18/mgkit`, or copy `skills/` into the tool's skills directory.

## Kickoff lines for execute-plan

| Harness | Small plan (one file) | Big plan (folder) |
|---|---|---|
| Claude Code | `/mgkit:execute-plan plan/<date>-<slug>.html` | `/goal Use the mgkit execute-plan skill on plan/<date>-<slug>/ until every task in TODO.md that is not a USER TASK is checked or blocked.` |
| Codex | `$execute-plan plan/<date>-<slug>.html` | `/goal Use $execute-plan on plan/<date>-<slug>/ until every task in TODO.md that is not a USER TASK is checked or blocked.` |
| OpenCode | `Use the execute-plan skill on plan/<date>-<slug>.html` | `Use the execute-plan skill on plan/<date>-<slug>/` (no goal mode: the skill keeps looping itself) |
| Pi | `/skill:execute-plan plan/<date>-<slug>.html` | `/skill:execute-plan plan/<date>-<slug>/` (no goal mode: the skill keeps looping itself) |

## Pending manual verification

- [ ] Codex: in a logged-in session with mgkit installed, confirm the `$` picker lists the plugin skills and whether they are namespaced (`$execute-plan` vs `$mgkit:execute-plan`); update the kickoff table if namespaced.
- [ ] Codex: confirm `/goal` exists in 0.144.6 and accepts a `$skill` mention in its condition.
- [ ] OpenCode: in a logged-in session, confirm the model loads a plugin-registered skill via the `skill` tool.
- [ ] Pi: in a logged-in session, confirm `/skill:<name>` runs a skill from a package installed with `pi install`. (Automated attempt on 2026-09-17 reached the model provider but failed with HTTP 429 usage limit.)
