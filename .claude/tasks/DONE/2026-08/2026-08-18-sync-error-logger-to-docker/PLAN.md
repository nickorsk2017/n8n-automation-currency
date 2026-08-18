# PLAN — 2026-08-18-sync-error-logger-to-docker

## v1

### R1 — extend Data Table provisioning
Generalize `scripts/create_data_table.sh` from one hardcoded table to a small
loop over a table-spec list, mirroring how `scripts/import_credentials.sh`
already handles two credentials in one script rather than one script per
credential. Keep the existing idempotency check (GET+filter by name, skip if
present, treat 409 on POST as already-exists) per table, so a partial prior
run (e.g. `currency_rates` exists, `error_log` doesn't) still converges
correctly. Column list for `error_log` — `source_workflow`, `context`,
`message`, all string — is a literal transcription of
`docs/workflows/error-logger/README.md`, matching the existing comment
convention that names the doc as source of truth. No new Makefile target:
`make setup-data-table` keeps its name and now provisions both tables.

### R2 — import order / same-id resolution
No script change needed. `scripts/import_workflow.sh` already upserts by the
JSON's own top-level `id` (confirmed in its precondition check and the n8n
CLI's own behavior noted in its comments). Since `error-logger.json`'s `id`
is `w5dvcvpZ5b9AVTLC` — the same id `ai-chat-currency-agent.json`'s two
Execute Workflow nodes reference — importing both via `make import-all`
(which iterates `workflows/*.json` in directory listing order, i.e.
alphabetical: `ai-chat-currency-agent.json` before `error-logger.json`)
still ends with both workflows present under matching ids. Import order does
not matter for the import step itself: `Execute Workflow` only stores a
`workflowId` value, resolved at *execution* time, not at import time — so
neither workflow's import can fail from the other not existing yet. Record
this reasoning in EXEC.md rather than changing `import-all`'s iteration
order.

One real risk worth a doc note (not a script change): `AI Chat Currency
Agent`'s `callerPolicy` is `workflowsFromSameOwner`. On a single-admin
Docker stand (the only topology this repo provisions) both workflows are
owned by the same user, so this resolves without action — call this out in
case someone later adds a second Docker user/project.

### R3 — no workflow JSON changes
Confirmed: this task touches only `scripts/` and `docs/`.

### R4 — docs
Add a short "Docker stand" note to `docs/workflows/error-logger/README.md`
stating `error_log` is provisioned by `make setup-data-table` and the
workflow by `make import-all`, matching the pattern already documented for
`currency_rates` in `docs/workflows/rate-loader/`. Makefile help text
(`setup-data-table`'s `##` comment) gets updated to mention both tables by
name instead of only `currency_rates`.

### R5 — cannot execute here
No `docker`/`docker compose` in this sandbox and `localhost:5678` refused a
connection (checked). EXEC.md must describe the script/doc changes made and
explicitly state the Makefile targets were not run in this session — the
Engineer runs `make setup-data-table && make import-all` on a Docker-capable
machine to actually perform the sync.

### Files touched
- `scripts/create_data_table.sh`
- `docs/workflows/error-logger/README.md`
- `Makefile` (help text only, `setup-data-table` line)
