# TASK — 2026-08-18-openai-rate-limit-error-handling
owner: Engineer
immutable: true

## Requirements
- R1: The `OpenAI Chat Model - GPT` node in the AI Chat Currency Agent
  workflow intermittently fails on the free/trial OpenAI tier (most likely
  cause: rate limiting), but the current failure is opaque -- no log entry
  and no explicit error surfaced to the chat user. Add explicit error
  handling on this node's failure path: (a) an error is logged with enough
  detail to identify the cause (node name, error message/status, timestamp),
  and (b) the chat user sees an explicit, human-readable error response
  instead of a silent/generic failure.
- R2: Implement and verify this change first on the live n8n Cloud instance
  (workflow id `bLflLYfGzORWkjJV`, "AI Chat Currency Agent") via the n8n MCP.
- R3: After the Cloud version is verified working, bring the self-hosted
  Docker instance (`docker-compose.yml`) to the same state, and re-export
  the updated workflow JSON to `workflows/ai-chat-currency-agent.json` so
  the repo file matches both live instances (per the root CLAUDE.md export
  discipline rule).
- R4: No secrets (API keys) are written into the exported workflow JSON.
- R5: New/changed nodes follow the repo's n8n conventions: descriptive
  `<Kind> - <What>` names, a `notes` value explaining the node's purpose and
  referencing this task's requirement id.

## Acceptance
- A1: On the live Cloud instance, forcing/observing an `OpenAI Chat Model -
  GPT` failure produces a logged error entry and a visible error message
  returned to the chat user (no silent failure).
- A2: The same behavior is present on the Docker instance after import.
- A3: `workflows/ai-chat-currency-agent.json` reflects the final node graph
  from both live instances (export discipline satisfied).
- A4: No API keys or other secrets appear anywhere in the exported JSON.
- A5: `docs/workflows/chat-agent/` is updated to describe the new
  error-handling behavior if it documents the node graph/behavior already.

## Constraints
- Touches: live Cloud workflow (via MCP), live Docker workflow (via
  import), `workflows/ai-chat-currency-agent.json`, possibly
  `docs/workflows/chat-agent/README.md` -> multi-file / cross-instance ->
  MEDIUM, per Planner to confirm or escalate to HIGH if the design requires
  schema/infra changes beyond node-level error handling.

## Amendment — 2026-08-18, Engineer
The Docker half of R3 and its acceptance A2 are **descoped from this task** and
moved to `2026-08-18-sync-chat-agent-to-docker`.

Reason: R3 part 2 requires `make import` and `make drift` against the local
Docker stand, which needs a running Docker daemon and `N8N_API_URL`/`N8N_API_KEY`
for that container. No actor working this task can reach either, so the task
cannot close on its own merits no matter how many iterations it runs — the
blocker is access, not work. Holding the task open only keeps the commit gate
shut on work that is finished.

Scope of this task is now the Cloud implementation, the repository export and
the documentation, all of which are verified. R3 reads "repository JSON synced"
only; the Docker instance is the successor task's subject.

Note: the chat-agent graph has changed substantially since this task executed
(task 2026-08-18-guardrail-error-logging-and-static-agent-error). The successor
task therefore imports the current file, not this task's intermediate shape,
which is another reason the Docker step belongs outside this task rather than
inside it.
