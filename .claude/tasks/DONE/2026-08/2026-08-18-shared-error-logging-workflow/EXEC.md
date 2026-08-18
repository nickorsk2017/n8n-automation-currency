# EXEC — 2026-08-18-shared-error-logging-workflow

## v1

Built per PLAN.md v1, dev stand (n8n Cloud) via MCP, then exported.

1. Data Table `error_log` created (id `Q8vyD2SotqKTWB8x`, project
   `7be3175KDEz3HrYS`): columns `source_workflow`, `context`, `message`
   (all string). Satisfies R2.
2. Workflow `Error Logger` created (id `w5dvcvpZ5b9AVTLC`) via
   `create_workflow_from_code`, then published/activated:
   - `Execute Workflow Trigger - Log Error Entry` (`workflowInputs`:
     `source_workflow`, `context`, `message`, all string).
   - `Data Table - Insert Error Row` (`dataTableId` mode `name` ->
     `error_log`; `defineBelow` columns 1:1 from the trigger fields).
   Satisfies R1.
3. Live `AI Chat Currency Agent` (id `bLflLYfGzORWkjJV`) updated atomically
   (14 ops) via `update_workflow`, then published:
   - Added `Execute Workflow - Log Agent Error` (executeWorkflow v1.3,
     `source: database`, `workflowId` mode `id` -> `w5dvcvpZ5b9AVTLC`,
     `onError: continueRegularOutput`), wired
     `AI Agent - Currency Assistant` (output index 1) -> it -> `Set - Format
     Agent Error`. `message` expression mirrors `Set - Format Agent Error`'s
     own fallback: `$json.error && $json.error.message ? ... : 'AI Agent
     failed (no error message available)'`.
   - Added `Execute Workflow - Log Tool Error` (same pattern), wired
     `IF - Input Valid` (output index 1) -> it -> `Stop And Error - Invalid
     Input`. `context` includes `$json.error_code`; `message` is
     `$json.message` (same field `Stop And Error - Invalid Input` already
     reads).
   - Removed `NoOp - Log Agent Error` and `NoOp - Log Tool Error`.
   Satisfies R3, R4, R5 (fixed `id`-mode workflowId, no by-name option on
   this node per `get_node_types`), R6 (names, notes, no Code node, no
   secrets — verified no literal keys in either exported file).
4. Exported: `workflows/error-logger.json` (new),
   `workflows/ai-chat-currency-agent.json` (updated node/connection graph,
   same wrapper shape as before). Both re-fetched from the live instance
   after publishing so file and instance agree (R7, R8, A3).
5. Docs: `docs/workflows/error-logger/README.md` (new, contract + schema +
   callers). `docs/workflows/chat-agent/README.md` updated: node-graph
   diagram and the "Agent-level failure handling" section now name the
   `Execute Workflow - Log *` nodes and point to the new workflow's docs
   directory instead of describing the old bare NoOp nodes. `docs/
   architecture.md` gained one paragraph + link in the data-flow section.
   `docs/README.md` directory listing gained the new entry (R9).

## Out of scope (confirmed unchanged)
- `workflows/currency-rate-loader.json` — not touched.
- Prod stand (Docker) — not synced; live/export changes are dev-stand only,
  matching the pattern of prior tasks in this repo.

## Files touched
- `workflows/error-logger.json` (new)
- `workflows/ai-chat-currency-agent.json`
- `docs/workflows/error-logger/README.md` (new)
- `docs/workflows/chat-agent/README.md`
- `docs/architecture.md`
- `docs/README.md`

## v2 (addresses VALIDATION v1 open_issues V1-A3, V1-N1)

- V1-A3: Re-synced `workflows/error-logger.json` to the live workflow exactly
  (node ids `6deb1164-...`/`4a0216cd-...`, positions `[0,0]`/`[224,0]`,
  notes without the hand-added task-reference suffix that was never
  submitted to `create_workflow_from_code`). Repo and instance now agree.
- V1-N1: Updated live `bLflLYfGzORWkjJV` via `update_workflow`
  (`setNodeParameter`, path `/notes`) on `AI Agent - Currency Assistant` and
  `Stop And Error - Invalid Input` to name `Execute Workflow - Log Agent
  Error` / `Execute Workflow - Log Tool Error` instead of the removed NoOp
  nodes, published, then mirrored the same two notes strings into
  `workflows/ai-chat-currency-agent.json`.
