# VALIDATION — 2026-08-08-2026-08-08-loader-fetch-upsert

## v1
Result: FAIL

Checked against TASK.md A1-A7 / PLAN.md P1-P9:
- A1 PASS — HTTP Request node fetches freecurrencyapi /latest, base_currency bound
  to Set - Loader Config, no literal apikey (expression on `$env.FREECURRENCYAPI_KEY`).
- A2 PASS — Code - Rates To Rows produces exact
  `{base_currency, target_currency, rate, fetched_at}` shape; confirmed in EXEC.md
  execution 2 data.
- A3 PASS — Data Table - Upsert Rate Row upserts on (base_currency, target_currency);
  EXEC.md execution 3 confirms re-run updates existing row ids 1-4, no duplicates.
- A4 PASS — IF - Response OK / IF - Rows Valid guards plus HTTP error output all
  converge on NoOp - Log Loader Error, isolated from the write path; EXEC.md
  execution 1 confirms the error path fires cleanly without corrupting data.
- A5 FAIL — no screenshot exists under `screenshots/`. EXEC.md records this as a
  tooling limitation (Chrome extension not connected, computer-use not enabled),
  not a workflow defect, but the acceptance criterion is unmet as written.
- A6 PASS — README.md "Data Table schema" section documents the schema, upsert
  rationale, and error-handling trade-off; stale "not stored in this repo"
  sentence corrected.
- A7 PASS — no literal secret in workflows/1-currency-rate-loader.json.

Issues:
- {id: V1-1, type: requirement, severity: blocking, ref: "TASK.md R5/A5", note: "Screenshot of a successful execution cannot be produced in this session (no Chrome/computer-use access). Requires an Engineer decision: enable one of those tools and resume, or amend R5/A5 to accept the recorded n8n MCP execution evidence (EXEC.md executions 1-3) in place of a UI screenshot."}

STATE: stage=VALIDATED, status=FAIL, validation_version=1, next_actor=Engineer (issue type=requirement)

## v2
Result: FAIL

Re-checked after EXEC.md v2 (exec_version=2):
- A1 PASS (strengthened) — execution 16 is a real call to freecurrencyapi.com via a
  Query Auth credential, not a pinned/simulated response; returned 33 live rates.
  Still no literal key in workflows/1-currency-rate-loader.json (credential
  reference only).
- A2-A4, A7 — unaffected by this change, still PASS per v1 findings; execution 16
  additionally confirms A2-A4 against real data (33 correctly-shaped rows, both
  guards passed, no error-path pollution of currency_rates).
- A3 — real upsert observed: 4 of the 33 rows reused existing ids from the earlier
  pin-data test (createdAt unchanged, updatedAt advanced); the other 29 were new
  inserts. Consistent with idempotent upsert behavior.
- A5 still FAIL — no screenshot under `screenshots/`. Chrome extension confirmed
  still unreachable this session (retried after Engineer selected "enable Chrome
  extension"). Not a workflow defect; a session tooling-access gap.
- A6, R6 — unaffected, still PASS.

Issues: V1-1 unchanged (still open, unresolved — screenshot capability not
available). No new issues.

STATE: stage=VALIDATED, status=FAIL, validation_version=2, next_actor=Engineer (issue type=requirement, unchanged: V1-1)

## v3
Result: PASS

TASK.md amended by Engineer (R5/A5): screenshot is explicitly out of scope for this
repo (Engineer sends it via email instead); EXEC.md's recorded real execution
(execution 16 — live freecurrencyapi call, 33 rows upserted into live
`currency_rates`) now satisfies A5 as rewritten.

Full re-check against amended TASK.md:
- A1 PASS, A2 PASS, A3 PASS, A4 PASS, A5 PASS (amended), A6 PASS, A7 PASS.

Issues: none. V1-1 resolved by TASK.md amendment (Engineer decision), cleared.

STATE: stage=DONE, status=PASS, validation_version=3, next_actor=none
