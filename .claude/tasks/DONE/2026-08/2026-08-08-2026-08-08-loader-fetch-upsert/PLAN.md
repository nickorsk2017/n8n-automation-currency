# PLAN — 2026-08-08-2026-08-08-loader-fetch-upsert

## v1

### Context checked
- Live n8n instance reachable via MCP. Workflow `1 - Daily Currency Rate Loader`
  exists (Schedule Trigger only). Data Table `currency_rates` already exists live
  with columns base_currency/target_currency/rate/fetched_at — matches
  docs/data-table-schema.md. No stored credential for freecurrencyapi yet.
- `n8n-nodes-base.dataTable` (row resource) has a native `upsert` operation
  ("update row(s), or insert if there is no match") — this replaces the
  lookup-then-branch pattern implied by TASK.md R3's "e.g." wording. Recommend
  using it directly; simpler, fewer nodes, same idempotency guarantee.
  Because the row count from one `/latest` call is small (tens of currencies,
  not 100+), a `splitInBatches` loop is not required for performance — `splitOut`
  (array -> items) feeding the dataTable node per item is sufficient. Note this
  deviation from R3's example wording in EXEC.md.
- README.md's "Setup" section currently states screenshots are "not stored in
  this repository," but `.gitignore`'s own R3 comment says screenshots/ is
  intentionally tracked. Existing inconsistency, not introduced by this task.
  Executor should fix the stale README sentence while touching README for R6.

### Node sequence (Workflow 1, extending existing Schedule Trigger)
1. `Schedule Trigger - Daily FX Pull` (existing, untouched).
2. `Set - Loader Config` — defines `base_currency` (single configurable field,
   default `USD`) consumed downstream. Satisfies R1's "parameter, not hardcoded."
3. `HTTP Request - Fetch Latest Rates` — GET freecurrencyapi `/latest`,
   `base_currency` bound to step 2's field via expression, API key sent as a
   header/query expression reading `{{$env.FREECURRENCYAPI_KEY}}` (env-injected
   per root CLAUDE.md, no credential object needed, no literal key in JSON).
   Configure on-error = continue with a separate error output branch (not a hard
   stop) so failures route into the error path instead of aborting silently.
   Satisfies R1, R4 (HTTP-failure branch).
4. `IF - Response OK` — validates the parsed body actually contains a non-empty
   `data` object (a 200 with a malformed/empty body must not be treated as
   success). False branch -> error path. Satisfies R4 (partial/invalid response
   guard, distinct from the transport-level error output of step 3).
5. `Code - Rates To Rows` — Code node (justified: turning an object keyed by
   currency code into an array of `{base_currency, target_currency, rate,
   fetched_at}` rows, with a computed ISO-8601 `fetched_at`, is not expressible
   with Set/Split alone). Satisfies R2.
6. `IF - Rows Valid` — explicit partial-data guard: array non-empty AND every row
   has all four fields non-null. False branch -> error path. Satisfies R4.
7. `Split Out - Rows To Items` — array -> individual items for the write step.
8. `Data Table - Upsert Rate Row` — `n8n-nodes-base.dataTable`, resource=row,
   operation=upsert, target table `currency_rates`, match fields
   (base_currency, target_currency). Satisfies R3.
9. Error convergence: outputs of step 3's error branch, step 4 false, and step 6
   false all feed one `NoOp - Log Loader Error` node carrying the failing item's
   error/validation context. No new Data Table for errors — keeps scope to
   TASK.md's minimum ("Log/NoOp node" option); a dedicated errors table is a
   future enhancement, not required by A4. Satisfies R4 (isolated error branch,
   no corruption of `currency_rates`).

### Credential/secret handling
No n8n credential object is created. `FREECURRENCYAPI_KEY` is read at
execution time via `$env` expression (already documented in README/.env.example
from a prior task). Satisfies R1/A1/A7 (no literal key in exported JSON).

### Test execution & evidence (R5/A5)
Use the n8n MCP `execute_workflow`/`test_workflow` tool for a functional test run
first (fast feedback, confirms upsert behavior on a re-run = no duplicates,
confirms error branch on a forced-bad input if feasible). Then capture the
required UI screenshot of a successful execution via the Chrome/computer-use
tooling against the n8n editor (Executor decides which is available in-session)
and save it under `screenshots/`.

### Documentation (R6/A6)
Fill README.md's "Data Table schema" placeholder section with: the four-column
schema (already in docs/data-table-schema.md, summarized not duplicated), the
upsert-key rationale, and the error-handling trade-off (transport errors vs.
payload validation errors both funnel to one log point rather than a persisted
errors table, chosen for scope minimalism). Also fix the stale "screenshots not
stored in this repo" sentence noted above.

### Risks / open questions
- No freecurrencyapi credential exists yet; plan assumes `$env` expression
  access at execution time (consistent with prior task's design and
  .env.example). If the execution sandbox cannot actually reach
  freecurrencyapi.com or resolve `$env.FREECURRENCYAPI_KEY`, Executor must
  record this as a limitation in EXEC.md rather than fabricate a successful
  test run — mirrors how the prior task handled "no reachable n8n instance."

STATE: stage=PLANNED, next_actor=Executor, plan_version=1
