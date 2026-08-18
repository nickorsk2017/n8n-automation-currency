# PLAN — 2026-08-18-shared-error-logging-workflow

## v1

### New workflow: Error Logger
- File: `workflows/error-logger.json`. Two nodes only.
- `Execute Workflow Trigger - Log Error Entry` (executeWorkflowTrigger, inputSource
  `workflowInputs`): declares fields `source_workflow` (string), `context` (string —
  which node/branch raised the error), `message` (string). No `occurred_at` field;
  the Data Table's own `createdAt` system column is the timestamp (R2), avoiding a
  redundant column and any Code node.
- `Data Table - Insert Error Row` (dataTable, resource=row, operation=insert):
  `dataTableId` mode `name` (per root CLAUDE.md's resource-locator guidance — this
  node supports by-name resolution, unlike the caller-side reference in R5), columns
  mapped 1:1 from the trigger's three fields via `defineBelow` + expressions.
  `options.optimizeBulk` left off (default) since each call is a single row and the
  caller may want the insert result.

### New Data Table
- Name `error_log`, columns: `source_workflow` (string), `context` (string),
  `message` (string). Created via MCP `create_data_table` before the workflow is
  built, so the Insert node's resource-mapper schema can resolve real columns.

### workflows/ai-chat-currency-agent.json changes (R3, R4)
- Both replacements use `n8n-nodes-base.executeWorkflow` v1.3, `mode: once`,
  `source: database`, `workflowId: { __rl: true, mode: 'id', value: <fixed id> }`
  — `id` mode is used, not `list`, because the fixed-id-checked-into-JSON pattern
  (root CLAUDE.md n8n conventions) is what survives a fresh instance; `list` mode
  caches a name lookup that is not portable. The fixed id is Error Logger's real
  workflow id, assigned once the Executor creates it via MCP, and is recorded in
  both files' `notes` per R6.
- `workflowInputs` (resourceMapper, `defineBelow`) supplies `source_workflow:
  "AI Chat Currency Agent"` literal, and `context` / `message` bound by expression
  to whatever fields are actually present on the item at each node's position
  (AI Agent's `Error` output for the agent-error replacement; the tool-input
  validation Code node's error output for the tool-error replacement). Executor
  confirms exact field names by inspecting live upstream node output before wiring
  the expressions — do not guess field names.
- Node names: `Execute Workflow - Log Agent Error` and `Execute Workflow - Log Tool
  Error` (keeps the `<Kind> - <What>` convention while dropping the now-inaccurate
  "NoOp" kind).
- Preserve exact existing downstream connections: agent-error node -> `Set - Format
  Agent Error`; tool-error node -> `Stop And Error - Invalid Input`. No other
  connections change.
- Risk: a failure inside Error Logger (e.g. a Data Table hiccup) must not also take
  down the parent workflow's already-in-progress error path, which exists specifically
  for user-visible failure handling. Executor sets `onError: continueRegularOutput`
  (or the node's equivalent error-handling option) on both new Execute Workflow nodes
  so a logging failure cannot mask or replace the original error being reported.
- `options.waitForSubWorkflow` stays at its default `true`: the parent path should
  not proceed to `Set - Format Agent Error` / `Stop And Error - Invalid Input` before
  the row is written, so the two remain ordered.

### Build order (dev stand, n8n Cloud, via MCP — docs/architecture.md)
1. Create Data Table `error_log`.
2. Create workflow `Error Logger`, containing the two nodes above; note its
   assigned id.
3. Update live `AI Chat Currency Agent` (id `bLflLYfGzORWkjJV`): replace the two
   NoOp nodes in place, rewire using the Error Logger id from step 2.
4. Export both workflows to `workflows/error-logger.json` and
   `workflows/ai-chat-currency-agent.json`.

### Docs impact (R9)
- New `docs/workflows/error-logger/README.md`: input contract (three fields),
  `error_log` schema, and that it is called by `ai-chat-currency-agent` today and
  intended for any future workflow.
- One-line link addition in `docs/architecture.md`'s data-flow section noting
  errors are centrally logged.
- If `docs/workflows/chat-agent/README.md` currently documents `NoOp - Log Agent
  Error` / `NoOp - Log Tool Error` by name, update those mentions to the new node
  names and add the directory link; if it does not mention them, no change needed
  there (Executor confirms against the current file, not this plan).

### Explicitly out of scope (per TASK.md Constraints)
- `workflows/currency-rate-loader.json` is untouched.
- No prod-stand (Docker) sync in this task.

### Files touched
- `workflows/error-logger.json` (new)
- `workflows/ai-chat-currency-agent.json` (modified)
- `docs/workflows/error-logger/README.md` (new)
- `docs/architecture.md` (small edit)
- `docs/workflows/chat-agent/README.md` (conditional small edit)
