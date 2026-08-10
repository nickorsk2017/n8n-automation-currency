# Documentation

How the system works **now**. No task ids, no decision history, no record of
what was tried and rejected — that lives in the execution harness under
`.claude/tasks/`. These pages are rewritten in place when the system changes.

Operational instructions are not here either; they live in the `Makefile`,
next to the commands they describe.

- [architecture.md](architecture.md) — layers, the two n8n stands, data flow
- [workflows/rate-loader/](workflows/rate-loader/) — the daily rate loader and the data table it writes
- [workflows/chat-agent/](workflows/chat-agent/) — the chat agent and its conversion tool

## Sync to Notion

This folder is mirrored to Notion under
[N8N Workflows](https://app.notion.com/p/3b739cf0f2ac81c4892cfaef9fd1f251), for
readers who do not open the repository. The repository is the source; Notion is
the copy.

The mirror is refreshed on request — ask Claude to sync the documentation and it
regenerates the pages from these files. Only pages under `N8N Workflows` are
touched; nothing else in the workspace is read or modified.
