# TASK — 2026-08-09-wf1-error-logging-timezone
owner: Engineer
immutable: true

## Requirements
- R1: Replace the empty `NoOp - Log Loader Error` convergence node in
  workflows/1-currency-rate-loader.json with a real logging path. The test
  brief's Workflow 1 requirement 4 says a failed freecurrencyapi call "should
  log the error"; a parameterless NoOp records nothing, and the execution is
  still reported as successful, so an operator cannot tell a failed daily run
  from a good one.
- R2: The new path must emit a structured error record identifying which of the
  three failure sources fired (HTTP transport/status error, invalid API
  response payload, invalid transformed rows), a human-readable message, the
  configured base_currency, and a timestamp.
- R3: The run must be marked as failed in n8n's execution list so a silently
  broken loader is visible without opening each execution.
- R4: The error path must remain fully isolated from the Data Table write, so
  the "failure must never corrupt stored data" rule in root CLAUDE.md continues
  to hold after the change.
- R5: Make the daily 06:00 schedule genuinely UTC. The Schedule Trigger node's
  own note concedes 06:00 is instance-local and only equals UTC if the instance
  timezone happens to be UTC; the brief asks for a reasonable daily time such as
  06:00 UTC.
- R6: Re-export the updated workflow to workflows/1-currency-rate-loader.json
  per the Export discipline section of root CLAUDE.md.

## Acceptance
- A1: workflows/1-currency-rate-loader.json contains no parameterless NoOp on
  the error path; all three failure branches converge on a node that produces a
  structured record with failure_stage, error_message, base_currency and
  failed_at.
- A2: The error path terminates in a node that marks the execution as failed.
- A3: No connection exists from any error-path node to
  `Data Table - Upsert Rate Row`.
- A4: docker-compose.yml sets the instance timezone to UTC so the Schedule
  Trigger's 06:00 is UTC, and the Schedule Trigger note no longer claims the
  timezone is unverified.
- A5: The live workflow and the exported file agree on the error path.

## Constraints
- Two files touched (workflows/1-currency-rate-loader.json, docker-compose.yml)
  -> MEDIUM.
- No secrets in the exported JSON; credential references only.
- Out of scope, tracked separately: the workflow id drift between the exported
  file (OgOk0TrsiV3xsNv9) and the live instance (iBdFv2bTfVR7chbE), and the
  stale live workflow description. Both belong to the export/sync task.
