# TASK — 2026-08-17-sync-stop-and-error-to-cloud
owner: Engineer
immutable: true

## Requirements
- R1: The live n8n Cloud instance (workflow id `bLflLYfGzORWkjJV`, "AI Chat
  Currency Agent") does not yet reflect task 2026-08-17-stop-and-error-after-
  log-tool-error: it is missing the `Stop And Error - Invalid Input` node and
  the connection from `NoOp - Log Tool Error` to it. Update the live workflow
  via the n8n MCP so its node graph matches `workflows/ai-chat-currency-agent.json`.
- R2: Add node `Stop And Error - Invalid Input` (`n8n-nodes-base.stopAndError`,
  typeVersion 1), params `errorType: "errorMessage"`,
  `errorMessage: "={{ $json.message }}"`, with the same `notes` as in the
  repo JSON.
- R3: Add connection `NoOp - Log Tool Error` -> `Stop And Error - Invalid
  Input` (main, index 0).
- R4: Do not modify any other node, connection, credential, or setting on the
  live workflow.

## Acceptance
- A1: `get_workflow_details` on `bLflLYfGzORWkjJV` shows the new node and
  connection present, matching the repo JSON.
- A2: No other part of the live workflow changed (spot-checked against the
  pre-update state).

## Constraints
- Live n8n instance only; no repository files are touched by this task
  (`workflows/ai-chat-currency-agent.json` already reflects the target state
  from the prior task).
