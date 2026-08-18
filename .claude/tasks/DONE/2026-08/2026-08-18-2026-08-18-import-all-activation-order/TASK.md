# TASK — 2026-08-18-2026-08-18-import-all-activation-order
owner: Engineer
immutable: true

## Requirements
- R1: `make import-all` must succeed end-to-end on a clean instance. Currently it
  fails: `scripts/import_workflow.sh` imports+activates each file under
  `workflows/*.json` in a single pass, in filesystem (alphabetical) order.
  `ai-chat-currency-agent.json` sorts before `error-logger.json`, so n8n tries to
  activate the chat agent — whose `Execute Workflow - Log Agent Error` / `Execute
  Workflow - Log Tool Error` nodes reference the error-logger sub-workflow
  (`w5dvcvpZ5b9AVTLC`) — before that sub-workflow has even been imported, let
  alone published. Observed failure:
  `POST /api/v1/workflows/bLflLYfGzORWkjJV/activate` -> HTTP 400,
  `Cannot publish workflow: Node "Execute Workflow - Log Agent Error" references
  workflow w5dvcvpZ5b9AVTLC which is not published; ...`.
- R2: The fix must not depend on manually reordering files alphabetically (fragile,
  breaks silently if a filename changes) — it must guarantee any workflow a file
  references via `toolWorkflow`/`executeWorkflow` node `workflowId` is imported
  and activated/published before the referencing file is activated.

## Acceptance
- A1: `make import-all` run against a clean n8n instance imports and activates
  all three workflows in `workflows/` with no manual re-run and no activation
  error.
- A2: The ordering/dependency fix is expressed in the import tooling (Makefile
  and/or `scripts/import_workflow.sh`/a new script), not by relying on
  alphabetical filename order.
- A3: Existing single-file `make import FILE=...` behavior is unchanged for a
  workflow with no sub-workflow dependencies.

## Constraints
- Do not edit workflow JSON node logic — this is an import-tooling/ordering bug,
  not a workflow-design bug.
- Follow n8n conventions in root CLAUDE.md for activation (Public API
  `POST /workflows/:id/activate`, not the deprecated `update:workflow` CLI).
