# TASK — 2026-08-08-2026-08-08-loader-fetch-upsert
owner: Engineer
immutable: true

## Requirements
- R1: Add an HTTP Request node to Workflow 1 (`workflows/1-currency-rate-loader.json`)
  that calls the freecurrencyapi.com `/latest` endpoint, with `base_currency` supplied
  as a parameter (variable/config), not hardcoded. The API key must come from
  environment/credential injection, never a literal in the exported JSON (per root
  CLAUDE.md secrets rule).
- R2: Add a Code or Set node that transforms the API response into an array of rows
  shaped as `{ base_currency, target_currency, rate, fetched_at }`, matching the
  `currency_rates` Data Table schema already defined in `docs/data-table-schema.md`.
- R3: Write those rows into the `currency_rates` Data Table using an upsert pattern:
  loop over rows (e.g. Split In Batches) and use the Data Table node with
  update-if-exists / insert-if-not-exists semantics keyed on
  (base_currency, target_currency), per root CLAUDE.md "Workflows are re-runnable".
- R4: Add error handling:
  - Detect and branch on HTTP failure / non-OK response (e.g. `continueOnFail` +
    IF-check on status, or an Error Trigger / error workflow — Planner decides which).
  - Validate the transformed response is complete before writing; an incomplete or
    invalid payload must not reach the Data Table write path (partial-data guard).
  - Log errors on an isolated error branch (e.g. a dedicated Log/NoOp node or a
    write to a separate errors table) rather than letting failures corrupt
    `currency_rates`.
- R5: Produce a successful test execution of the updated workflow. Amended
  2026-08-08 (Engineer): the screenshot itself is out of scope for this repo -
  Engineer will capture and send it via email outside the repository, not commit
  it under `screenshots/`. Recorded n8n MCP execution evidence (EXEC.md) stands
  in place of a screenshot as proof of a successful run for this task.
- R6: Document the rationale for the `currency_rates` schema and the upsert/error
  handling design in terms suitable for inclusion in `README.md` (schema rationale
  section).

## Acceptance
- A1: `workflows/1-currency-rate-loader.json` contains an HTTP Request node fetching
  `/latest` from freecurrencyapi.com with `base_currency` as a configurable
  parameter, and no literal API key anywhere in the file.
- A2: A transform step (Code/Set) produces rows in the exact
  `{ base_currency, target_currency, rate, fetched_at }` shape.
- A3: The workflow writes to the `currency_rates` Data Table via an upsert keyed on
  (base_currency, target_currency); re-running the workflow does not create
  duplicate rows.
- A4: There is an explicit validation/guard step preventing partial or malformed
  data from reaching the Data Table write, with failures routed to a separate error
  branch that logs the error.
- A5 (amended 2026-08-08, Engineer): no screenshot required under `screenshots/`.
  Satisfied by EXEC.md recording a real, non-simulated successful execution
  (execution 16: live freecurrencyapi call via the `freecurrencyapi` credential,
  33 rows correctly upserted into the live `currency_rates` Data Table).
- A6: `README.md` (or PLAN.md, per Planner's call on placement) documents the schema
  rationale and error-handling trade-offs.
- A7: No secrets appear anywhere in `workflows/1-currency-rate-loader.json`.

## Constraints
- Follow root CLAUDE.md n8n conventions: descriptive typed node names
  (`<Kind> - <What>`), `notes` on every non-obvious node referencing the requirement
  id it satisfies, prefer built-in nodes over Code nodes (a Code node is justified
  only where built-ins cannot express the logic, e.g. cross-rate arithmetic or
  complex validation).
- Data Table schema must match `docs/data-table-schema.md`; if a change to that
  schema is needed, Planner must call it out explicitly.
- All persisted content (TASK/PLAN/EXEC/VALIDATION/JSON node names/notes/README) in
  English.
- Builds on top of the DONE task `2026-08-08-2026-08-08-currency-rate-loader`
  (Schedule Trigger + Data Table definition already in place); do not re-litigate
  that scope, only extend it.
