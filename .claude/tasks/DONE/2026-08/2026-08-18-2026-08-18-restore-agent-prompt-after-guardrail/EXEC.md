# EXEC — 2026-08-18-restore-agent-prompt-after-guardrail
owner: Executor
exec_version: 1

## Applied to Cloud `bLflLYfGzORWkjJV`, published `fb2db5b8`
`AI Agent - Currency Assistant`:
- `promptType`: `"auto"` -> `"define"`
- `text`: `={{ $json.chatInput || $json.guardrailsInput }}`

Nothing else changed. `validationWarnings` empty.

## NOT verified
A1 and A2 are both unclaimed. Cloud has no OpenAI quota so the agent cannot run
here, and Docker is unreachable. No execution was run as a substitute, and no
structural argument is offered in place of one — PLAN v1 forbids it, and this is
the third defect in a row that reached the Engineer because someone accepted
reasoning where a run was required.

## Repository
`workflows/ai-chat-currency-agent.json` re-exported from the published graph:
zero residual node-field differences against Cloud excluding `credentials`,
`connections` identical, secret scan clean.

## Docs
Not touched. `docs/workflows/chat-agent/README.md` documents the guardrail's
Pass/Fail/error routing and the terminal-node contract; neither changed. Whether
the agent's prompt is read automatically or by expression is node-internal
detail the page does not currently enumerate, and adding it would duplicate the
node's own `notes`.

## Handoff
`make import-all` on Docker, then one conversion question in the widget.
Expected: a converted amount. If instead another `error_log` row appears, it now
carries the serialised item, so it will say what failed rather than that
something did.
