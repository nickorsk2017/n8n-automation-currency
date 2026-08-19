# VALIDATION — 2026-08-18-agent-base-currency-not-hardcoded
validation_version: 2
result: PASS

## v1
result: FAIL

### Verified
- A2 PASS. The three conversions were re-derived from the stored rates
  (EUR 0.8633641547, JPY 159.3400272464) and match executions 180-182 exactly.
- A3 PASS. Live Cloud read hashed against the repository export: `jsCode`
  `1da97bbd...f3d14822`, `systemMessage` `c9cf9229...0788a292`, `notes`
  `f6995976...db5f103d`, 23 nodes both sides, `active: true`.
- A4 PASS. No surviving claim in `docs/` that the agent assumes USD; remaining
  mentions are the loader's configured base, the schema example, and format examples.
- Differential execution of the old and new `jsCode` over 22 input shapes under
  Node 22: all single-base cases byte-identical, including from-leg-before-to-leg
  error precedence, empty-table `EUR->JPY` / `EUR->USD` / `USD->USD`, and the
  `UNKNOWN_CURRENCY` cases. `fetched_at`, staleness and rounding unchanged.
- Sentinel audit clean: `findRate` returns an object, `'SUPERSEDED_BASE'`, or `null`;
  the string sentinel cannot collide with a code admitted by `^[A-Z]{3}$`.
- Harness clean: write order, legal transitions, scope, English-only, no secrets,
  no new Code nodes, loader and lookup node untouched.

### Issues
- V1 {type: architecture, severity: blocking, ref: workflows/ai-chat-currency-agent.json
  node `Code - Compute Conversion` `notes`}: the note still says "USD-based table",
  leaving a base-currency literal inside the node this task de-hardcodes and, per
  A1, not as a format example. PLAN P6 required rewording it; EXEC could not, because
  MCP `update_workflow` has no operation that sets an existing node's top-level
  `notes` (settable only via `addNode`) and a repo-only edit would break A3. A plan
  step the mandated tooling cannot express is a planning defect: the Planner must
  choose the mechanism or amend the scope.
- V2 {type: requirement, severity: blocking, ref: `jsCode` empty-rows branch}: on an
  empty table `EUR->EUR` and `XYZ->XYZ` now return `success, rate 1` where the old
  code returned `NO_RATE_DATA`. R3 requires behaviour preservation for a USD-based
  table; PLAN P2 chose this deliberately and EXEC disclosed it, but neither may
  waive a requirement. Engineer ratification is required. If accepted, note the
  consequence: an unknown code answered against itself succeeds on an empty table
  and fails with `UNKNOWN_CURRENCY` on a populated one.
- V3 {type: logic, severity: minor, ref: `jsCode` `baseCurrency` fallback}: when no
  fetched row carries `base_currency`, the base-leg shortcut is lost and a base leg
  reports `UNKNOWN_CURRENCY` rather than `NO_RATE_DATA` — the wrong error class for
  what is a data problem. Unreachable while the schema guarantees the column.
- V4 {type: logic, severity: minor, ref: `jsCode` `findRate` superseded-base branch}:
  detection keys on the code appearing as a `target_currency`, so it can never fire
  for the previous base itself (the loader stores no row whose target is its base).
  Mid-migration, `USD->JPY` with EUR as the new base returns `UNKNOWN_CURRENCY` —
  precisely the message PLAN P4 exists to avoid, in its most likely case.
- V5 {type: logic, severity: minor, ref: `jsCode` `byFetchedAtDesc`}: base selection
  depends on `fetched_at` being an ISO-8601 string. A `Date` value would sort by day
  name and could select the superseded base. The old code shared the assumption but
  it only affected the reported timestamp, not the arithmetic.
- V6 {type: logic, severity: minor, ref: docs/workflows/chat-agent/README.md,
  `alwaysOutputData` paragraph}: "turns 'no rows' into `UNKNOWN_CURRENCY` or
  `NO_RATE_DATA`" is now stale — zero rows yields `NO_RATE_DATA` or a `rate: 1`
  success, never `UNKNOWN_CURRENCY`.

### Routing
Type priority requirement > architecture: next_actor = Engineer (V2), then Planner (V1).
V3-V6 are non-blocking and are carried for the actor that next touches the node.

## v2
result: PASS

### Verified
- A1 PASS. No currency literal remains as a control-flow constant in the agent's Code
  nodes, its system prompt, or the recreated node's notes. The five surviving `USD`
  strings in the workflow JSON are format examples (validator message, `$fromAI`
  hints, tool description, greeting).
- A2a / R3a PASS, by executing the shipped `jsCode` under Node 22 rather than reading
  it: an empty row set returns `NO_RATE_DATA` for `X->X`, `base->base` and `X->Y`
  alike, with no exception.
- A2 / R3 PASS. The three reference conversions reproduce exactly
  (18455.714935 @ 184.557149, 7967.001362 @ 159.340027, 115.825981 @ 1.15826), and a
  populated single-base table still reports `UNKNOWN_CURRENCY` for an unknown code
  with the from-leg reported before the to-leg.
- V3, V4, V5 closed by execution: rows without a recorded base, rows carrying two
  bases, and an unparseable `fetched_at` all behave as PLAN v2 specifies.
- A3 PASS, and stronger than in v1: `versionId == activeVersionId ==
  53be2e39-e8e1-4cf9-bc0f-8d168ba34926`, `sameAsDraft: true`. Repository, Cloud draft
  and published version agree on `jsCode` (`663402c1...db66e8ce`), `notes`
  (`2681df64...891c41f5d1`), node id `4541ac32-2e0c-46ef-b7b0-c04db3dd5858` and the
  `Data Table - Get Rate Rows` connection.
- A4 PASS. No claim that the agent assumes USD survives, and the `NO_RATE_DATA`,
  `UNKNOWN_CURRENCY` and `alwaysOutputData` statements match executed behaviour.
- Harness PASS: `ci_check.py` clean, legal transitions, `## v1` blocks preserved with
  `## v2`/`## v3` appended, English only, scope held (loader, schema and
  `Data Table - Get Rate Rows` untouched), no secrets, no new Code nodes.

### Issues raised in this round
- V7 {type: logic, severity: minor, ref: EXEC.md v2 Checks}: A2's numeric evidence is
  a local run of the shipped code rather than a live Cloud execution, because
  `get_execution` and `search_executions` became unavailable mid-session. Live runs
  185 (post-recreation) and 186 (post-publish) completed successfully, which
  exercises the recreated node and its inbound connection but does not reproduce the
  numbers. Residual risk accepted: the executed source is byte-identical to the
  published version by sha256, and executions 180-182 recorded the same numbers from
  the same stored rows earlier in the task.
- V8, V9 closed by EXEC v3 (artifact version headers; `UNKNOWN_CURRENCY` row wording).
- V10 {type: logic, severity: minor, ref: `jsCode` `fetchedAtMs`}: a newer row with an
  unparseable `fetched_at` loses base selection to an older ISO-stamped row. This is
  the direction P5' chose deliberately and is stated in the node comment; recorded as
  a known property, not a defect.

### Routing
PASS. open_issues cleared, stage DONE.
