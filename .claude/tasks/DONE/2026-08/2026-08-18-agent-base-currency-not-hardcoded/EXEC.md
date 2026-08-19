# EXEC — 2026-08-18-agent-base-currency-not-hardcoded
exec_version: 3

## v1

### Implemented
- P1, P3: `Code - Compute Conversion` derives the base from the `base_currency` of the
  most recently fetched row (`fetched_at` descending) and restricts the lookup set to
  rows carrying that base. The literal base constant is gone.
- P2: the empty-result guard now fires on "no rows and the two codes differ"; a code
  into itself with no rows returns rate 1. No base is referenced.
- P4: a code present only on a superseded-base row reports `NO_RATE_DATA` with a
  message naming the code; an absent code still reports `UNKNOWN_CURRENCY`. Error
  ordering (from-leg before to-leg) is unchanged.
- P5: system prompt rule 1 now speaks of "the base currency that the stored rates are
  quoted against" and adds an explicit instruction not to assume a particular base.
  Currency codes survive only as format examples in rules 2-3.
- P6: applied to Cloud workflow `bLflLYfGzORWkjJV` via MCP `update_workflow`
  (2 operations, version "Derive base currency from stored rows").
- P7: repository export patched to the same two field values; parity confirmed by
  sha256 of both fields against a fresh Cloud read (jsCode
  `1da97bbd...f3d14822`, systemMessage `c9cf9229...0788a292`), node list identical.
- P8: docs corrected — cross-rate section, `NO_RATE_DATA` row, quoted system prompt
  and the rule-1 rationale paragraph in the chat-agent page; data-flow step 6 in
  `architecture.md`.

### Live checks (Cloud, manual executions on the tool sub-workflow)
- 180: 100 EUR -> JPY = 18455.714935 @ 184.557149
- 181: 50 USD -> JPY = 7967.001362 @ 159.340027
- 182: 100 EUR -> USD = 115.825981 @ 1.15826
- 183: 10 XYZ -> JPY = UNKNOWN_CURRENCY
All match the values the previous implementation produces from the same stored rows
(EUR 0.8633641547, JPY 159.3400272464, both `fetched_at` 2026-08-18T06:00:24.105Z).

### Deviations
- Plan step P6 also called for rewording the node `notes` on `Code - Compute
  Conversion`. The MCP `update_workflow` operation set has no node-notes operation,
  and changing the notes in the repository file alone would break Cloud/repo parity
  (A3). The existing note describes the table as USD-based, which remains a true
  statement of the current data rather than a claim about the code, so it was left
  as-is on both sides.
- The empty-table case `X -> X` for a non-base code now returns rate 1 instead of
  `NO_RATE_DATA`. This follows directly from P2 and is the only behavioural change
  outside the requirements' stated cases.

### Observed, out of scope
- `Data Table - Get Rate Rows` sets two `target_currency` conditions with no explicit
  combinator. Live runs return both legs' rows, so it behaves as OR, but the
  behaviour is implicit. Constraint forbids touching it; warrants its own task.

### Changed files
- `workflows/ai-chat-currency-agent.json`
- `docs/workflows/chat-agent/README.md`
- `docs/architecture.md`
- Cloud workflow `bLflLYfGzORWkjJV` (not a repository file)

## v2
Addresses V1 via PLAN v2 (P2', P4', P5', P6', P9). v1 remains as the record of the
first attempt.

### Implemented
- P2': the empty-row branch returns `NO_RATE_DATA` unconditionally (R3a). The
  code-into-itself carve-out is gone.
- P4': `rowSetIsAuthoritative` gates the `UNKNOWN_CURRENCY` claim — a base must have
  been derived and every fetched row must share it. Otherwise an unmatched code is
  reported as `NO_RATE_DATA` naming the code.
- P5': base selection sorts on `Date.parse`, with unparseable timestamps last.
- P6': `Code - Compute Conversion` removed and re-added in one atomic
  `update_workflow` call carrying the new notes, with the inbound connection from
  `Data Table - Get Rate Rows` re-added in the same call. Node id changed to
  `4541ac32-2e0c-46ef-b7b0-c04db3dd5858`; the repository export carries the new id.
- P9: the `alwaysOutputData` paragraph, the `NO_RATE_DATA` row and the cross-rate
  section of the chat-agent page now describe the current behaviour.

### Publication (found during P7 verification)
MCP `update_workflow` edits the Cloud DRAFT; the active version is separate. Both the
v1 and v2 edits had landed on the draft only, so the live workflow was still running
the hardcoded implementation. `publish_workflow` was called; active version is now
`53be2e39-e8e1-4cf9-bc0f-8d168ba34926`. This is a general property of the MCP editing
path, not a one-off: any Cloud change through this route needs an explicit publish
before it is live.

### Checks
Differential run of the shipped `jsCode` under Node 22 over 15 row-set shapes:
- 100 EUR->JPY = 18455.714935 @ 184.557149; 50 USD->JPY = 7967.001362 @ 159.340027;
  100 EUR->USD = 115.825981 @ 1.15826 — unchanged from v1 and from the pre-task code.
- XYZ->JPY and JPY->XYZ on a populated single-base table: `UNKNOWN_CURRENCY`, from-leg
  first (V4 fix does not swallow the ordinary case).
- Empty table: `EUR->EUR`, `USD->USD`, `EUR->JPY` all `NO_RATE_DATA` (R3a, A2a).
- Rows without `base_currency`: base leg reports `NO_RATE_DATA`, not `UNKNOWN_CURRENCY`
  (V3).
- Mid-migration rows (EUR newly base, stale USD row): `USD->JPY` reports
  `NO_RATE_DATA`; `JPY->EUR` resolves against the new base at 0.00542 (V4).
- Non-ISO `fetched_at` on the newer row: the ISO-stamped base still wins (V5).
- Stale rates beyond 36h: `is_stale: true` (unchanged).
Cloud draft vs repository export: `jsCode`, `notes` and `systemMessage` sha256 all
match, connections deep-equal, 23 nodes, same names, position and typeVersion.

### Changed files (v2)
- `workflows/ai-chat-currency-agent.json`
- `docs/workflows/chat-agent/README.md`

## v3
Bookkeeping and wording only; no workflow or Cloud change, so repository/Cloud parity
established in v2 is untouched.
- V8: `PLAN.md` and `EXEC.md` version headers now agree with `STATE.yaml`.
- V9: the `UNKNOWN_CURRENCY` row of the error table states the condition under which
  the code is claimed, so the row no longer overstates when read on its own.
- V10 is accepted as the documented consequence of P5' and needs no change.

### Changed files (v3)
- `docs/workflows/chat-agent/README.md`
