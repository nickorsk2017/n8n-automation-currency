# EXEC — 2026-08-08-2026-08-08-loader-fetch-upsert

## v1
Changed files:
- workflows/1-currency-rate-loader.json (extended)
- README.md (Data Table schema section filled; stale screenshots sentence fixed)
- Live n8n workflow `1 - Daily Currency Rate Loader` (iBdFv2bTfVR7chbE) updated via
  n8n MCP `update_workflow` (19 operations, 8 new nodes) — export above reflects it.

Implemented per PLAN.md P1-P9 node sequence:
- Set - Loader Config, HTTP Request - Fetch Latest Rates (onError=continueErrorOutput,
  apikey via `$env.FREECURRENCYAPI_KEY` expression, no credential object, no literal
  key) — P2/P3.
- IF - Response OK, Code - Rates To Rows, IF - Rows Valid, Split Out - Rows To Items,
  Data Table - Upsert Rate Row (native upsert op, matched on base_currency +
  target_currency) — P4-P8.
- NoOp - Log Loader Error as single convergence point for all three failure branches
  (HTTP error output, Response-OK false, Rows-Valid false) — P9.

Test evidence (live n8n instance, workflow iBdFv2bTfVR7chbE):
- Execution 1 (execute_workflow, real $env lookup): the sandboxed n8n instance denies
  `$env` access at runtime ("access to env vars denied"). This is an environment
  constraint, not a workflow defect — confirmed the error path works as designed: the
  HTTP node's error output fired and routed cleanly to NoOp - Log Loader Error with
  execution status "success" (no crash, no partial write).
- Execution 2 (test_workflow, pinned HTTP Request output only, per that tool's
  documented "bypass external services" behavior): full downstream pipeline ran for
  real — Code transform produced 4 correct rows, both IF guards passed, Split Out
  produced 4 items, Data Table - Upsert Rate Row inserted 4 new rows (ids 1-4) into
  the live `currency_rates` data table.
- Execution 3 (same pattern, changed rate values): Data Table - Upsert Rate Row
  updated the same row ids 1-4 (createdAt unchanged, updatedAt advanced, rate
  changed) — confirms upsert idempotency (A3): re-running does not create duplicates.

Limitation / open item for Validator: R5/A5 (screenshot of a successful execution
under `screenshots/`) is NOT done. Chrome extension (`mcp__claude-in-chrome`) is not
connected in this session and desktop screenshot access (computer-use) is not
enabled, so no UI screenshot could be captured. Execution 2's full run (including a
real Data Table write, verified above) is the closest available evidence of a
successful execution; it is not a screenshot. Per PLAN.md's risk note, recording this
as a limitation rather than fabricating a screenshot.

STATE: stage=EXECUTED, next_actor=Validator, exec_version=1

## v2
Changed files:
- workflows/1-currency-rate-loader.json (HTTP Request node auth + notes updated)
- README.md (Setup section: Cloud $env limitation + Query Auth credential documented)
- Live n8n workflow `1 - Daily Currency Rate Loader` (iBdFv2bTfVR7chbE), HTTP Request
  node reconfigured via n8n MCP `update_workflow`.

Root cause found for the exec_version=1 "access to env vars denied" result: this n8n
Cloud instance blocks `$env` access outright, independent of what's actually in the
environment. Engineer (interactively, via n8n UI) created a Query Auth credential
("freecurrencyapi", type httpQueryAuth, id yAID5rimNxWhXskI) holding the real
freecurrencyapi key. HTTP Request - Fetch Latest Rates switched from
`authentication: none` + `$env` query-param expression to
`authentication: genericCredentialType` / `genericAuthType: httpQueryAuth` with that
credential attached. Exported JSON updated to match (holds only the credential
name/id reference, never the key value — A7 still holds).

Test evidence (execution 16, live n8n instance, real API call, no pin data):
Full production-shaped run against the real freecurrencyapi endpoint. HTTP Request
returned a real 33-currency rate object; both IF guards passed; Split Out produced 33
items; Data Table - Upsert Rate Row wrote/updated all 33 rows in the live
`currency_rates` table (row ids 1-33, mix of new inserts and updates to the four rows
from earlier pin-data tests). This supersedes the exec_version=1 pin-data test as the
primary evidence for A1-A4/A7 — it is a genuine end-to-end success, not simulated.

Still open: A5 (screenshot under `screenshots/`) — Chrome extension remains
unreachable from this session (retried, still not connected). Everything else needed
to close V1-1 is otherwise ready; only the UI screenshot capture step is blocked on
tooling access.

STATE: stage=EXECUTED, next_actor=Validator, exec_version=2
