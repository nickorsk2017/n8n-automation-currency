# TASK — 2026-08-18-sync-chat-agent-to-docker
owner: Engineer
immutable: true

## Context
Successor to `2026-08-18-openai-rate-limit-error-handling`, which was closed
with its Docker half descoped rather than done. The chat agent has been changed
on Cloud several times since (agent error branch, guardrail extraction, guardrail
error logging, static error messages) and `workflows/ai-chat-currency-agent.json`
now matches the published Cloud graph exactly. The self-hosted Docker stand has
received none of it.

This task is deliberately scoped to the sync, not to any of the changes being
synced — those are already implemented, exported and validated.

## Requirements
- R1: Bring the local Docker n8n instance to the state of
  `workflows/ai-chat-currency-agent.json`, and of `workflows/error-logger.json`
  which it now depends on via `Execute Workflow` nodes.
- R2: Confirm the repository file and the Docker instance agree afterwards,
  mechanically rather than by inspection.
- R3: `error_log` must exist on the Docker stand before the chat agent runs, or
  the logging branches fail at their first call.

## Acceptance
- A1: `make import-all` completes against the Docker stand with no activation
  error. (The dependency-ordered activation this needs was added by task
  2026-08-18-2026-08-18-import-all-activation-order and has itself never been
  run end-to-end against Docker — this task is also its first real exercise.)
- A2: `make drift ID=<docker_workflow_id> FILE=ai-chat-currency-agent.json`
  reports no drift.
- A3: A chat message on the Docker instance produces the same behaviour as
  Cloud: a guardrail outcome writes one `error_log` row, and the user receives a
  fixed message rather than raw error text.

## Constraints
- Requires the Engineer's machine: a running Docker daemon, and
  `N8N_API_URL`/`N8N_API_KEY` in `.env` pointing at the local container. No
  other actor can reach either. If those are absent, halt and say so rather than
  reporting a partial result.
- The Docker stand needs its own OpenAI credential (`llmOpenAiApiCred`), which
  is what the repository file references. Cloud carries no credential on the
  model nodes — it runs on n8n's built-in AI credits — so credential setup is
  genuinely Docker-only work and is not evidenced by anything on Cloud.
- Do not "fix" behaviour differences found on Docker by editing the workflow
  here. A real difference is a finding to report; this task syncs, it does not
  redesign.
