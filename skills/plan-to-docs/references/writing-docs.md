<!-- Adapted from https://github.com/chrisbanes/skills (skills/grounded-writing/SKILL.md and references/style-profile.md, commit 00bda528b7a13fb6ba475b0d50e50589aa5d274f), Apache License 2.0, Copyright (c) Chris Banes. Changes: condensed and refocused on project docs written from code. See THIRD_PARTY_NOTICES.md. -->
<!-- Adapted from https://github.com/mattpocock/skills (skills/productivity/writing-for-agents/SKILL.md, commit b0618bc436ad893b3c5e84e55fba86586d34a404), MIT License, Copyright (c) 2026 Matt Pocock. Changes: condensed to the rules that apply to docs and their pointers. See THIRD_PARTY_NOTICES.md. -->

# Writing project docs

Docs written by this skill have two readers: a person who opens the page to understand the project, and an agent that reaches it from a link in the agent instructions. Write for both: concrete enough for the person, predictable enough for the agent.

## Ground every sentence

- **Facts come from the code.** Each claim about behaviour must be something you read in the code or verified. Quote numbers exactly as the code defines them.
- **Separate fact from reason.** State what the code does, then (when it helps) why. A reason taken from a plan or a decision record is fine; an invented reason is not.
- **Mark what you could not verify.** Leave the claim out, or keep it with a short note that it is unverified. Never smooth over a gap.
- **Keep limits.** If a behaviour has a boundary that changes how a reader uses it (data that arrives a day late, a feature that is only on one platform), say so where the behaviour is described. A caveat earns its place only when it changes the reader's understanding.

## Shape each page

- **Open with what the page covers** and the one or two sentences a reader most needs: what the thing is, what it is for. Skip scene-setting.
- **Explain in a chain**: the part a reader sees, the mechanism behind it, the consequence. Introduce a term where it starts to matter, and put a table, a snippet or a file path right after the claim it supports.
- **Use structure for reference, prose for reasoning.** Tables suit comparisons, inventories and schedules (tables, jobs, modules). Short paragraphs suit how and why. Headings expose the content of the page; do not add a heading to make sections look symmetric.
- **Co-locate.** Keep a concept's definition, rules and caveats under one heading so reading one part brings the rest.
- **End once.** The last section ends on its last useful point. No summary of the page, no closing call to action.

## Keep one source of truth

- **Link instead of copying.** Each meaning lives in one place. Another page that needs it links there.
- **The repository is a source of truth.** Versions, script flags, folder layouts and config values live in their files; a doc that restates them is a copy that will go stale. Restate only what a reader cannot find by looking: the convention nobody wrote down, the reason for a choice, the gotcha no config file confesses.
- **Leave out implementation detail that does not change how someone uses or changes the code.** Keep a constant when it defines behaviour a reader depends on (a retry interval, a retention window); drop one that is only an internal tuning value.

## Write in the present tense, without history

- Describe the project as it is. A doc that says "now", "no longer", "was changed to" or "in milestone 3" is a diff against a past the reader never saw. Rewrite it as the current rule.
- Drop incident stories, ticket numbers and plan IDs. Keep the lesson as a rule with its reason ("Segment downloads check the scheme, not the host, because Apple serves them from presigned storage URLs").

## Prose

- Plain words, concrete nouns, ordinary verbs. Use technical terms precisely and put identifiers in inline code.
- No marketing words, unsupported superlatives or certainty the evidence does not give.
- Vary sentence length naturally; keep paragraphs short and focused.
- Write the target behaviour positively ("Every string lives in `strings.xml`") rather than as a list of bans. Keep a prohibition only when it is a hard rule that cannot be phrased positively, and pair it with what to do instead.
- Read the page once for style and once for truth before you finish.

## Pointers from the agent instructions

The table in the agent instructions is what tells an agent to open a page. Its wording decides whether the page gets read.

- One row per page: the link, then what the page covers, starting with the words an agent would be thinking when it needs the page ("Database, sync, schedules…").
- Name distinct topics, not synonyms of the same one.
- Keep each row to one line. The page carries the detail; the row only has to make the agent reach for it.

## Final check

- Every path and identifier in the page exists in the repository.
- Every number matches the code.
- Nothing in the page describes plan history, and nothing contradicts another doc.
- A newcomer could act on the page without reading the plan it replaced.
