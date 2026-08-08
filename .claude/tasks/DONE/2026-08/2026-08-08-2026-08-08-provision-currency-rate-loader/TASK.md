# TASK — 2026-08-08-2026-08-08-provision-currency-rate-loader
owner: Engineer
immutable: true

## Context
Prior task `2026-08-08-2026-08-08-currency-rate-loader` (DONE/PASS) produced
repository artifacts only (`workflows/1-currency-rate-loader.json`,
`docs/data-table-schema.md`) because no live n8n instance was reachable at the
time. The n8n MCP connector is now reconnected. This task provisions the
corresponding live objects on the user's n8n instance via MCP, using the
repository artifacts as the exact spec (source of truth per root CLAUDE.md).

## Requirements
- R1: Create the `currency_rates` Data Table on the user's n8n instance via the
  n8n MCP `create_data_table` tool, matching `docs/data-table-schema.md` exactly:
  columns `base_currency` (string), `target_currency` (string), `rate` (number),
  `fetched_at` (string), no more/no fewer columns.
- R2: Create the workflow in the live n8n instance from
  `workflows/1-currency-rate-loader.json` via the n8n MCP SDK flow
  (`get_sdk_reference` -> `search_nodes`/`get_node_types` as needed ->
  `validate_workflow` -> `create_workflow_from_code`), reproducing the single
  `Schedule Trigger - Daily FX Pull` node (n8n-nodes-base.scheduleTrigger,
  interval=days, triggerAtHour=6, triggerAtMinute=0) with its existing `notes`
  content preserved.
- R3: Resolve target project via `search_projects` before creating — do not
  assume personal project without checking, per n8n MCP tool guidance.
- R4: If the live-created workflow's structure differs from
  `workflows/1-currency-rate-loader.json` in any way (IDs, positions are exempt;
  node type/parameters are not), re-export and overwrite the repo JSON so the
  repo stays the source of truth per root CLAUDE.md Export Discipline.
- R5: Do not create the freecurrencyapi/LLM credentials or write any secret
  values via MCP — out of scope, no secrets exist in this task's artifacts.

## Acceptance
- A1: `search_data_tables` (or equivalent) confirms `currency_rates` exists on
  the instance with exactly the 4 columns from R1.
- A2: `get_workflow_details` on the newly created workflow confirms one Schedule
  Trigger node configured for 06:00 daily.
- A3: `validate_workflow` passed before creation (recorded in EXEC.md).
- A4: No credentials/secret values were created or embedded during this task.
- A5: If R4 triggered a re-export, the repo JSON and live workflow match; if not,
  EXEC.md states they already matched.

## Constraints
- Follow n8n MCP server's mandated call order (SDK reference before code,
  best-practices lookup, node type lookup before parameters).
- Root CLAUDE.md n8n conventions still apply (descriptive node names, notes,
  idempotent behavior).
- All persisted content in English.
