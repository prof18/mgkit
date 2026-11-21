# Workers

How the orchestrator starts, talks to, stops and resumes workers. Verified with Claude Code 2.1.323 on 2026-11-21.

## Which kind of worker

| | Background session (`claude --bg`) | Subagent inside the orchestrator's session |
|---|---|---|
| Lifetime | Its own process; survives an orchestrator restart | Ends with the parent session |
| Working directory | Its own, in its own worktree | The parent's |
| Waiting for replies | Idles between turns and is woken by a message, for hours if needed | Cannot wait; it returns once |
| Visibility | `claude agents`, `claude attach <id>`, `claude logs <id>`, the Claude app | Only through the parent |
| How results come back | Messages, at every question and checkpoint | One final report |

Use background sessions for ticket workers. Subagents are not supported as workers, because no reply path to a waiting subagent was verified; use them only for short read-only lookups.

## Start a worker

1. Create the worktree with `git worktree add -b <branch> <path> <base>`, naming the worktree and branch after the ticket, with the base branch from setup.
2. Write the spawn prompt to a file in the session scratch directory: the spawn line, then the request. Keep the request to the skill and the ticket's id or path, for example `build ticket #12`; never paste ticket text into it, because the prompt passes through a shell command.
3. Start the session in the worktree. Pass `--permission-mode` with this session's own mode: a session in another mode holds incoming messages for its user's approval, and the protocol stalls.

```
cd <worktree path>
claude --bg --name <project>-<ticket>-worker --permission-mode <this session's mode> \
  "$(cat <prompt file>)"
```

`claude --bg` prints the session id; record it in the roster.

## Talk to a worker

- The session listing shows this session's own name first ("This session is …") and every other session by name.
- Send a message to the worker's session name. A message wakes an idle background session and arrives tagged with this session's name.
- Ask to be told when a worker goes idle instead of polling the listing.
- A worker's reply arrives only when the worker sends a message back; its plain output stays in its own session.
- A `claude -p` session ends when its turn ends, so it cannot wait for replies: use `--bg`.

## Wait caps

An idle worker cannot wake itself unless its harness lets it schedule a wake-up. If this session stops, the workers wait. On restart, the roster lists them and the pending requests to answer.

## Stop and resume

- `claude stop <id>` stops a session and keeps its conversation. `claude rm <id>` removes it.
- `claude --bg --resume <session id>` continues a stopped session in the background, and `claude respawn <id>` restarts one.
- A worker that lost its session resumes from its mirror entries, as `../../build/references/delegated.md` says.

## Other harnesses

Codex, OpenCode and Pi have no verified way for one session to message another, so `orchestrate` supports Claude Code only for now.
