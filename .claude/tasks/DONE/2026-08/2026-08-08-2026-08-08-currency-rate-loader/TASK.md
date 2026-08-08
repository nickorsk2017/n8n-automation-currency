# TASK — 2026-08-08-2026-08-08-currency-rate-loader
owner: Engineer
immutable: true

## Requirements
- R1: Define the `currency_rates` Data Table as a repository artifact with columns:
  `base_currency`, `target_currency`, `rate`, `fetched_at`. The combination of
  `base_currency` + `target_currency` must act as a unique key (loader upserts on
  this key, per root CLAUDE.md "Workflows are re-runnable"). Amended 2026-08-08:
  this environment has no reachable n8n instance (no Docker, n8n MCP disconnected
  mid-task) - the repository definition is the source of truth for this task,
  matching root CLAUDE.md's "Workflow JSON in workflows/ is the source of truth for
  review, not the live n8n instance" principle applied to Data Tables. Live creation
  against a running n8n instance is deferred to whoever next has instance access.
- R2: Build Workflow 1 ("Daily Currency Rate Loader") starting with a Schedule Trigger
  node that fires daily at 06:00 UTC.
- R3: The 06:00 UTC fire time must not be hardcoded as an unchangeable value. The
  Planner must propose, in PLAN.md, concrete options for how the schedule can be
  changed later without editing the workflow deeply (e.g. trigger parameter left as
  an obviously-editable single field, values driven by an n8n Set/Config node,
  environment-driven schedule, or equivalent), and recommend one.
- R4: Only the Schedule Trigger + Data Table creation scope is covered by this task
  (fetching rates from freecurrencyapi.com and writing rows is out of scope here,
  unless the Planner determines the Data Table cannot be meaningfully validated
  without at least a stub write step).

## Acceptance
- A1 (amended): a repository-tracked Data Table definition for `currency_rates`
  exists documenting the four columns above and the (base_currency, target_currency)
  unique-key convention. Does NOT require live creation in a running n8n instance
  for this task to pass.
- A2: `workflows/1-currency-rate-loader.json` contains a Schedule Trigger configured
  for 06:00 UTC daily.
- A3: PLAN.md documents at least two concrete options for making the trigger time
  reconfigurable, with a recommendation, before Executor implements it.
- A4: No secrets (API keys) appear in the exported workflow JSON.

## Constraints
- Follow root CLAUDE.md n8n conventions: descriptive typed node names, notes on
  non-obvious nodes, prefer built-in nodes over Code nodes, idempotent/upsert writes.
- All persisted content (TASK/PLAN/EXEC/VALIDATION/JSON node names/notes) in English.
