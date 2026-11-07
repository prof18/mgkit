<!-- Adapted from https://github.com/rock3r/publish-spec (skills/publish-spec/references/house-style.md, commit cddbc2d91d7a77f8cdbeef715b62d7e610f04eb0), Apache License 2.0, Copyright 2026 Sebastiano Poggi. Changes: condensed to the prose, code-labelling and rewrite rules that help an implementing agent follow a plan. See THIRD_PARTY_NOTICES.md. -->
# Writing a plan

The reader is an agent that follows the text literally and can read English as a second language. Write so it never has to rebuild grammar or guess who acts.

These rules apply to the text you write. Keep the fixed text of the templates (the escaping note, the rules for the implementing agent, the conventions) as it is.

## Sentences

- Use active voice and name the actor: "`assemble-plan.sh` deletes the body file", not "the file is deleted".
- Name the file, symbol or command in place. Never refer back with "the former", "both" or "the other one".
- Write complete sentences. Do not drop verbs and articles to save words; cut a claim instead.
- Start every instruction and checklist bullet with a verb. Never write a bullet that is only a noun phrase, and never write `path — noun, noun, noun`.
- Do not use `→` or `=` in place of a verb in prose. Say what each step does.
- Use `must` for a rule and `can` for an option. Never `should`, `may` or `might` in an instruction.
- Put the condition first and keep an instruction to 20 words or fewer: "If the gate fails, stop."
- Keep descriptive sentences to 30 words or fewer and a paragraph to one idea.
- Prefer plain words: use, do, show, start, stop, get, before, to, because, also, but. Do not write utilize, leverage, ensure, facilitate, prior to, in order to, comprehensive, robust or seamless; state the exact property instead.

## Code

- Label every code sample in a `<p>` right before its `<pre>`, never inside the code block, so the label is not transcribed into a file. Use one of three labels: `Existing: <code>path:start-end</code>`, `Diff: <code>path</code>`, or `Sketch: <code>path</code>` for code that does not exist yet.
- In a diff, show real context lines. Never write an elision line (`…`, `// ...`, `# ...`) to skip lines; split the diff into two hunks. `assemble-plan.sh` rejects such a line. A bare `...` that is real code, such as a Python stub body, is allowed.
- Keep a code sample to at most 30 lines and lines to 90 characters or fewer. Show only the lines that carry the change.

## Content

- Write only what is true for this repository. If a sentence could move unchanged into another project's plan, replace it with the fact only this project has, or cut it.
- Never invent a name, number, version or path. If a fact is unknown, say so and verify it in an early step. Label a hypothetical example as one.
- Do not narrate how you planned ("I first looked at…"). State the finding.
- Do not tell the reader what matters ("note that", "importantly", "simply", "just"). Give the fact.
- Do not end with a summary that repeats the Goal.
- Leave no generation leftovers in prose: citation markers (`:contentReference[`, `oaicite:`) or placeholders (`XX%`, `[insert …]`). `assemble-plan.sh` rejects them outside code samples.

## Rewriting an existing plan

When you shorten or reword plan text, keep every threshold, default, limit, path, command, caveat and scope qualifier. Leave code samples and quoted text unchanged unless they are wrong. After renaming a heading or step, update every reference to it.
