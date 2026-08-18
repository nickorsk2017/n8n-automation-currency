# Documentation

How the system works **now**. No task ids, no decision history, no record of
what was tried and rejected — that lives in the execution harness under
`.claude/tasks/`. These pages are rewritten in place when the system changes.

Operational instructions are not here either; they live in the `Makefile`,
next to the commands they describe.

- [architecture.md](architecture.md) — layers, the two n8n stands, data flow
- [workflows/rate-loader/](workflows/rate-loader/) — the daily rate loader and the data table it writes
- [workflows/chat-agent/](workflows/chat-agent/) — the chat agent and its conversion tool
- [workflows/error-logger/](workflows/error-logger/) — the shared error-logging sub-workflow
