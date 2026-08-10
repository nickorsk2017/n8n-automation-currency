# EXEC — 2026-08-09-wf1-error-logging-timezone

## v1
Changed files:
- `workflows/1-currency-rate-loader.json` — removed `NoOp - Log Loader Error`;
  added `Code - Build Error Record` (same node id and canvas position, so the
  diff reads as a replacement) and `Stop and Error - Fail Loader Run`; rewired
  the three failure branches onto the Code node and the Code node onto Stop and
  Error; rewrote the Schedule Trigger note to state 06:00 UTC as fact; added
  `settings.timezone = "UTC"` per PLAN v2.
- `docker-compose.yml` — added `GENERIC_TIMEZONE=UTC` and `TZ=UTC` under an
  explicit `environment` block, with a comment explaining why they are not in
  the gitignored `.env`.

Live instance (iBdFv2bTfVR7chbE) updated with the same change set via nine
atomic operations, plus a workflow description that no longer claims
"Trigger-only scope; fetch/upsert logic is a separate task" — that text was
written when the workflow held one node and had been false since.

### Live evidence
- **Execution 39 (happy path, regression).** status=success. 33 rows upserted;
  every returned row shows `createdAt` still at 2026-08-09T06:00 with a fresh
  `updatedAt`, so the change did not turn the upsert into an append and the
  loader remains idempotent.
- **Execution 40 (error path, forced).** `base_currency` temporarily set to
  `ZZZ`; freecurrencyapi replied 422. Result:
  - execution `status: error` — R3 satisfied, the run is visibly failed;
  - `Code - Build Error Record` emitted
    `{workflow, failure_stage: "HTTP_FETCH", error_message: "freecurrencyapi
    request failed: 422 - {...The selected base currency is invalid...}",
    base_currency: "ZZZ", failed_at: "2026-08-09T16:06:00.221Z"}` — R2
    satisfied, every field populated;
  - the thrown message was
    `Currency rate loader failed [HTTP_FETCH]: freecurrencyapi request failed:
    422 - ...`;
  - `Data Table - Upsert Rate Row` does not appear in runData at all — it never
    executed, so R4 holds under a real failure, not just structurally.
  - `Set - Loader Config` restored to `USD` afterwards; the live node now
    matches the exported file.

### Finding — classification is branch-independent, and that mattered
The 422 did not arrive on the HTTP node's error output as PLAN v1 assumed; it
arrived via `IF - Response OK`'s false branch, because the node returned the
error body as data rather than raising. The record was still labelled
`HTTP_FETCH` correctly, because the classifier keys off the *shape* of the
incoming item rather than which branch delivered it. Had it keyed off the
branch — the obvious alternative implementation — this failure would have been
mislabelled `API_RESPONSE`. Worth keeping in mind if the classifier is ever
refactored.

### Known residual drift (not in scope, for the export/sync task)
- Exported file id `OgOk0TrsiV3xsNv9` != live id `iBdFv2bTfVR7chbE`, so
  `make import` would create a second workflow instead of updating this one.
- The MCP update interface exposes no operation for editing an existing node's
  `notes`, so the live `Schedule Trigger - Daily FX Pull` still carries the old
  timezone caveat text while the exported file carries the corrected text. New
  nodes added in this task do carry their notes.

STATE: stage=EXECUTED, next_actor=Validator, exec_version=1
