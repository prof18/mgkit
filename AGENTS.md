# Working on mgkit

- Skills live in `skills/<name>/SKILL.md`. Follow the authoring rules in `docs/authoring.md`.
- Gate: `scripts/check.sh` must exit 0 before every commit.
- Stage explicit paths only. Never stage `plan/`. Never push.
- Harness facts (install, invoke, goal mode) live in `docs/harnesses.md`; update it when a harness changes.
- Bump versions only with `scripts/bump-version.sh <x.y.z>`.
