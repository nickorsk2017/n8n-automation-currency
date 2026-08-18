# TASK — 2026-08-18-sync-error-logger-to-docker
owner: Engineer
immutable: true

## Requirements
- R1: The prod stand (self-hosted Docker, `docker-compose.yml`) does not yet
  know about the `error_log` Data Table or the `Error Logger` workflow added
  to the dev stand (n8n Cloud) by task 2026-08-18-shared-error-logging-workflow.
  `scripts/create_data_table.sh` only provisions `currency_rates`; extend the
  provisioning step so the Docker stand also gets `error_log` (columns
  `source_workflow`, `context`, `message`, all string — per
  `docs/workflows/error-logger/README.md`), idempotently, without breaking
  the existing `currency_rates` provisioning.
- R2: `make import-all` must be able to bring both `workflows/error-logger.json`
  and the updated `workflows/ai-chat-currency-agent.json` into the Docker
  stand correctly. `scripts/import_workflow.sh` upserts by the JSON's own
  top-level `id`, and `ai-chat-currency-agent.json`'s new Execute Workflow
  nodes reference Error Logger by that same fixed id
  (`w5dvcvpZ5b9AVTLC`) — confirm this still resolves correctly for a
  same-id import into a fresh/existing Docker stand, and note anything a
  person running the import needs to know (e.g. import order, if it matters).
- R3: Neither `error-logger.json` nor `ai-chat-currency-agent.json` needs a
  code change for this — they already carry `active: true` /
  `mode: "id"` correctly per the prior task. Do not re-touch their node
  graphs; this task is about provisioning tooling and docs, not workflow
  content.
- R4: Update whatever operational documentation describes first-run/sync
  steps (the Makefile's own target help text, `docs/workflows/error-logger/`
  if it should mention the Docker stand) so a person following it ends up
  with `error_log` created and both workflows imported, without a manual
  n8n UI step, consistent with root CLAUDE.md's "no exceptions" on secrets
  and the existing `setup`/`import-all` pattern.
- R5: This session's sandbox has no Docker daemon/binary and cannot reach
  `localhost:5678` — `make up`/`make setup`/`make import-all` cannot
  actually be executed here. Prepare the repository so that running them on
  a machine that does have Docker performs the sync correctly; do not claim
  the sync itself was executed if it was not.

## Acceptance
- A1: `scripts/create_data_table.sh` (or an equivalent, still reached via
  `make setup-data-table`) creates `error_log` with the three columns above
  when it does not yet exist, and is a no-op when it does; `currency_rates`
  provisioning is unchanged in behavior.
- A2: `make import-all` (or the individual `make import FILE=...` calls it
  wraps) imports `error-logger.json` and `ai-chat-currency-agent.json` such
  that the Execute Workflow nodes' fixed-id reference resolves on the Docker
  stand, with reasoning recorded for why (same-id upsert behavior already in
  `scripts/import_workflow.sh`).
- A3: No secrets appear in any changed script or doc.
- A4: This task's artifacts do not claim Docker commands were actually run
  in this session; they describe what running them on a Docker-capable
  machine will do.

## Constraints
- Files likely touched: `scripts/create_data_table.sh`, possibly `Makefile`
  help text, possibly `docs/workflows/error-logger/README.md` -> MEDIUM.
- Out of scope: changing workflow JSON content, changing the Cloud (dev)
  stand (already done), provisioning credentials (unaffected by this
  change).
