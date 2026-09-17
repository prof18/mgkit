---
name: roast
description: Roast and stress-test an idea, feature, project or requirements list before anything is planned or built. Critiques it honestly, then interviews the user in rounds until every decision is settled, hunts for a name when the thing is new, and writes the agreed decisions to a roast file. Use when the user says roast, grill, challenge, stress-test, let's discuss before building, validate these requirements, or is about to start something new.
---
<!-- Adapted from https://github.com/mattpocock/skills (skills/productivity/grilling/SKILL.md, commit 959a8e9f1edc3adbe2f7e3054bb6fbefa6696260), MIT License, Copyright (c) 2026 Matt Pocock. See THIRD_PARTY_NOTICES.md. -->

# Roast

Pressure-test an idea until you and the user share one clear picture of what will be built and why. The output is a set of decisions, not code.

## 1. Talk, don't build

- While the roast runs, do not create, edit or delete files and do not write code. The one exception is the roast file in phase 4, and only after the user confirms.
- Before phase 1, read everything the user points at: briefs, requirement lists, documents, folders, screenshots.
- Speak the user's language in the conversation. Write the roast file in English.

## 2. Phase 1: critique

Send one message before asking anything. Be direct and specific; skip compliments that carry no information. Use the headings below that have something real behind them and leave out the rest.

- **Worth building?** What problem this solves, who has that problem, and what happens if nobody builds it.
- **Prior art.** Search the web, and where relevant GitHub, package registries and app stores. Name existing solutions with links, and state what this idea must do differently to deserve to exist.
- **Feasibility.** Platform limits, API constraints, sandboxing, cost, performance. Check each factual claim against a source; mark anything you could not verify as unverified.
- **Risks and dark paths.** Security, data loss, maintenance load, lock-in, licensing.
- **Requirements check.** Only when the user supplied requirements: for each one say keep, change or drop, with a one-line reason, then list requirements that are missing.
- **Alternatives.** Simpler or different approaches, including not building it at all.

Close the critique with a one-line verdict, for example "Worth building if X; the risky part is Y." If the subject is new and has no settled name, run the name hunt (phase 3) now and include its table in this message. Then start round 1 in the same message.

## 3. Phase 2: rounds of questions

Treat the subject as a tree of decisions: settling one decision opens the ones that depend on it.

**What goes in a round.** Ask every open decision whose prerequisites are already settled, all together. Leave out any question whose answer depends on another question that is still open; it waits for a later round.

**Format every question exactly like this:**

```
❓ **Q1 - <short title>**: <the question, with the options when there are options>

➡️ <your recommended answer, with a one-sentence reason>

---
```

Number questions continuously within the round so the user can answer by number ("1 yes, 2 the second option, 3 no because…").

**Facts versus decisions.**
- Facts are your job. If a question needs something you can find out (read files, run read-only commands, search the web, check docs), find it instead of asking. If you can start subagents, use them for lookups; otherwise look things up yourself.
- Decisions belong to the user. Never settle a decision on the user's behalf, even when your recommendation seems obvious.
- Do not hold up a round for research. Ask the questions that don't depend on the pending lookup now; the dependent ones wait.

**After each set of answers.**
1. Restate briefly what is now settled.
2. If an answer reopens an earlier decision, say so and put that decision back into play.
3. Work out the new set of open decisions whose prerequisites are settled, and ask the next round.

**Steering.**
- There is no limit on the number of questions. If the user says to wrap up, stop asking and list what is still open.
- If the user answers "not sure" or replies with a question, explain the trade-off in two or three sentences and ask again with a recommendation.

## 4. Phase 3: name hunt (inside the first message)

Run this without asking whenever the subject is new and has no settled name (the user gave none, or said the name is open), as part of the first message after the critique. Skip it otherwise.

1. Propose 6 to 10 candidates that fit the subject: short, easy to say, not generic dictionary words.
2. For every candidate, check and report:
   - GitHub repositories with that exact name and meaningful traction.
   - The registries or stores that matter for this kind of project: npm, Homebrew, crates.io, PyPI, App Store, Google Play, Obsidian community plugins, VS Code Marketplace, or whichever apply.
   - Domain availability for `.com`, `.dev` and `.app`, using RDAP or `whois`. Report each as likely available, taken, or unknown.
3. Show a table with columns: name, meaning, conflicts found, domains, verdict. Recommend one.
4. Choosing the name is a decision: ask it in round 1.

## 5. Phase 4: alignment and the roast file

1. When no open decisions remain, post a compact summary of every decision and ask: "Are we aligned?" Do nothing else until the user confirms.
2. After confirmation, write the roast file. Save it to `plan/<YYYY-MM-DD>-<slug>.roast.md` at the repository root, using today's date and a slug of 2 to 5 lowercase ASCII words joined by hyphens, unless the user's instructions specify another location. Outside a repository, ask where to save it.
3. Fill in `templates/roast.md` from this skill's directory. Do not commit the roast file.
4. End with the next step. Recommend `plan` for a small feature or `plan-max` for a big one, using the size rule in `../plan/SKILL.md` (relative to this skill's directory; if that path cannot be resolved, look for `skills/plan/SKILL.md` inside the mgkit installation).
