# EXEC — 2026-08-18-sync-error-logger-to-docker

## v1

Per PLAN.md v1. No Docker commands were run in this session (no `docker`
binary in this sandbox; `curl localhost:5678` refused — checked before
starting). Everything below is a repo change only, to be applied by
running `make setup-data-table && make import-all` on a machine that
actually has the Docker stand.

1. `scripts/create_data_table.sh` rewritten: extracted a
   `create_table_if_missing <name> <columns-json>` function from the
   previous single-table script (same idempotency logic: GET+filter, skip
   if present, treat POST 409 as already-exists), then called it once for
   `currency_rates` (unchanged columns/behavior) and once for `error_log`
   (`source_workflow`, `context`, `message`, all string, per
   `docs/workflows/error-logger/README.md`). `chmod +x` reapplied;
   `bash -n` syntax-checked clean. Satisfies R1/A1.
2. Confirmed (read-only, no code change) that `scripts/import_workflow.sh`
   already upserts by each file's own top-level `id`, so importing
   `error-logger.json` (`id: w5dvcvpZ5b9AVTLC`) lands under the same id
   `ai-chat-currency-agent.json`'s two Execute Workflow nodes reference —
   the fixed-id reference resolves on Docker exactly as it does on Cloud.
   Import order doesn't matter for the import step (workflowId is resolved
   at execution time, not import time). Documented in
   `docs/workflows/error-logger/README.md`'s new "Docker stand" section
   instead of changing `import-all`. Noted the `callerPolicy:
   workflowsFromSameOwner` setting as a non-issue on this repo's
   single-admin Docker topology. Satisfies R2/A2.
3. No workflow JSON touched (R3).
4. Docs/Makefile updated: `Makefile`'s `setup-data-table` and `setup` help
   lines now name both tables; `docs/workflows/error-logger/README.md`
   gained a "Docker stand" section. Satisfies R4.
5. No secrets introduced or touched (A3) — the script change only adds a
   second call to the same table-creation logic; no new credential or key
   handling.

## Files touched
- `scripts/create_data_table.sh`
- `Makefile`
- `docs/workflows/error-logger/README.md`

## Not done (by design, R5)
`make setup-data-table` and `make import-all` were not executed — this
sandbox cannot run Docker. The Engineer needs to run those two targets (in
either order relative to each other's workflow imports, per point 2 above)
on the machine hosting the Docker stand to actually apply this sync.
