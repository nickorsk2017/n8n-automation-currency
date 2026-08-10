# TASK — 2026-08-08-fix-import-sqlite-constraint-id
owner: Engineer
immutable: true

## Requirements
- R1: Fix `make import FILE=1-currency-rate-loader.json` (built in task
  2026-08-08-import-workflow-json-docker-n8n, `scripts/import_workflow.sh`)
  so it succeeds against a running Docker n8n instance without a SQLite
  constraint error.

## Observed failure (Engineer, real run against local Docker n8n)
Command: `make import FILE=1-currency-rate-loader.json`
Output:
```
Importing 1 workflows...
An error occurred while importing workflows. See log messages for details.
SQLITE_CONSTRAINT: NOT NULL constraint failed: workflow_entity.id
SQLITE_CONSTRAINT: NOT NULL constraint failed: workflow_entity.id
```

## Fact gathered (Engineer, pre-Planner)
`workflows/1-currency-rate-loader.json` top-level keys:
`name, nodes, connections, pinData, settings, staticData, meta` — there is no
top-level `id` field. This is a known failure mode of n8n's
`import:workflow` CLI on some versions: without a top-level `id` in the
JSON, the CLI does not always generate one before the DB insert, and the
`workflow_entity.id` column is NOT NULL, so the insert fails.

## Acceptance
- A1: `make import FILE=1-currency-rate-loader.json` completes successfully
  against a running `make up` stack (Engineer will verify locally — no
  Docker daemon in the harness sandbox).
- A2: The fix does not violate the "secrets never live in workflow JSON"
  convention or otherwise change workflow business logic (nodes,
  connections) — only what's needed to make import succeed.
- A3: If the fix involves changing exported workflow JSON files, document
  why in the relevant doc/README so future exports don't regress (e.g. if
  the exporting method needs to change, or a post-export step is needed).

## Constraints
- Root cause and fix approach to be determined by Planner (e.g.: add a
  generated `id` field to exported workflow JSON before import; use a
  different n8n CLI invocation/flag; or confirm this is an upstream n8n bug
  requiring a documented workaround). Do not guess a fix without confirming
  cause via `get_workflow_best_practices` / n8n CLI docs where the n8n MCP
  is available.
- Must keep `scripts/import_workflow.sh` and `workflows/*.json` consistent
  with the export/import round-trip described in root CLAUDE.md's Export
  discipline section.
