# TASK — 2026-08-17-stop-and-error-after-log-tool-error
owner: Engineer
immutable: true

## Requirements
- R1: In `workflows/ai-chat-currency-agent.json`, add a Stop And Error node
  immediately after the `NoOp - Log Tool Error` node, on the invalid-input
  branch of `IF - Input Valid`. The new node must be named per the repo's
  `<Kind> - <What>` convention (e.g. `Stop And Error - Invalid Input`) and
  must carry a `notes` value explaining why it exists.
- R2: Wire the connection from `NoOp - Log Tool Error` to the new node so the
  branch terminates in an explicit thrown error instead of silently ending
  after logging.
- R3: Re-export the updated workflow to `workflows/ai-chat-currency-agent.json`
  (this JSON file is the source of truth, not the live n8n instance).

## Acceptance
- A1: `workflows/ai-chat-currency-agent.json` contains a Stop And Error node
  downstream of `NoOp - Log Tool Error`, connected via that node's output.
- A2: The new node follows naming and notes conventions from the root
  `CLAUDE.md` (`n8n conventions` section).
- A3: No secrets or credentials are introduced; no other nodes or connections
  in the workflow are altered.

## Constraints
- Single file touched: `workflows/ai-chat-currency-agent.json`.
- No new dependencies.
