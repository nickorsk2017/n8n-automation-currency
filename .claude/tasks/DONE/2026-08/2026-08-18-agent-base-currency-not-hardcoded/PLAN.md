# PLAN — 2026-08-18-agent-base-currency-not-hardcoded
plan_version: 2

## v1

### Decision
The base currency is data, not configuration. `currency_rates` already stores it per
row (`base_currency`), written by the loader from its own config field, so the rows
the tool already fetches carry the authoritative answer. The agent derives the base
from those rows rather than reading the loader's config (which it cannot see) or
gaining a config node of its own — a second config field would restore the same
two-copies-that-can-disagree failure this task exists to remove.

Rejected alternatives:
- A `Set` config node in the agent workflow mirroring the loader's base: reintroduces
  the divergence, merely relocating the literal.
- Passing the base in as a tool argument from the LLM: makes a data-integrity constant
  model-controlled; a hallucinated base silently corrupts arithmetic.
- Widening the Data Table read to look up the base row explicitly: an extra read per
  conversion for a value already present on every fetched row; also blocked by the
  task's constraint against touching the lookup node.

### Consequence
The base becomes unknowable only when zero rows come back, and in that state no
conversion needs it — see P2. Rows quoted against a superseded base (possible because
the loader upserts on `(base_currency, target_currency)` and never deletes) must not
be mixed into the arithmetic; they are excluded, and a leg left without a row is
reported as missing data rather than as an unknown code.

### Steps
- P1 (R1, R3): In `Code - Compute Conversion`, replace the base constant with a value
  derived from the fetched rows: the `base_currency` of the most recently fetched row.
  Restrict the row set used for lookup to rows carrying that same base, so a leftover
  row from a previous base cannot enter the cross-rate division.
- P2 (R1, R3): Restate the empty-result guard without reference to a base. With no
  rows there is exactly one answerable case — source and target are the same code,
  rate 1 — so the guard fires when no rows came back and the two codes differ. This
  preserves the existing outcome for a base-currency leg on an empty table
  (`NO_RATE_DATA`, not `UNKNOWN_CURRENCY`) without naming the base.
- P3 (R3): Keep the base leg's rate at 1 by comparing against the derived base, and
  leave its `fetched_at` contribution as today (the base row is not fetched, so
  freshness continues to come from the non-base leg). Rounding, staleness threshold
  and the success payload shape are untouched.
- P4 (R3): A leg whose code is absent from the base-filtered rows keeps reporting
  `UNKNOWN_CURRENCY`, except where the row set is empty (P2). A leg dropped solely
  because its row carries a superseded base reports `NO_RATE_DATA` — the code is
  recognised, the current base's data for it is not yet loaded.
- P5 (R2): Reword the system prompt's rule 1 so the always-call-the-tool instruction
  is expressed in terms of "the base currency the stored rates are quoted against"
  rather than a literal code, keeping the explicit no-exception wording and its
  rationale (only the tool holds the stored rate and its freshness). Currency codes
  remain permitted in rule 2/3 as format examples.
- P6 (R4): Apply P1-P5 to the Cloud workflow `bLflLYfGzORWkjJV` via the n8n MCP
  `update_workflow` before touching the repository. Update the node `notes` on
  `Code - Compute Conversion` to state that the base is derived, not assumed.
- P7 (R4, A3): Re-export the Cloud workflow into
  `workflows/ai-chat-currency-agent.json` in this task, and diff it against the
  pre-change file to confirm the only changes are the ones P1-P6 intend.
- P8 (R5, A4): Correct `docs/workflows/chat-agent/README.md` (cross-rate section,
  error-code table, quoted system prompt) and the base-currency sentence in
  `docs/architecture.md` to describe derivation from the stored data. `README.md`
  and `docs/workflows/rate-loader/` describe the loader's base and stay as they are.

### Impact
- Cloud workflow `bLflLYfGzORWkjJV`: `Code - Compute Conversion`,
  `AI Agent - Currency Assistant`.
- `workflows/ai-chat-currency-agent.json` (re-export).
- `docs/workflows/chat-agent/README.md`, `docs/architecture.md`.

### Risks
- The derived base is wrong if the table holds rows from two bases and the newest row
  belongs to the superseded one. Mitigated by deriving from the most recent
  `fetched_at`, which the loader stamps per run.
- Behavioural regression is invisible to a schema check; validation must exercise
  the three conversion shapes named in A2 against the live instance.
- Cloud and repository can drift between P6 and P7; P7 is not optional and its diff
  is the evidence.

### Validation hooks
- A1 by inspection of the exported JSON.
- A2 by live execution on Cloud, comparing against the values the current
  implementation returns for the same inputs.
- A3 by diff.
- A4 by grep over `docs/`.

## v2
Patches P2, P4, P6 of v1; all other v1 steps stand.

### Decision (amended)
Two things changed the shape of the plan. The Engineer ratified R3a: an empty lookup
answers `NO_RATE_DATA` unconditionally, so v1's "a code into itself is answerable
without data" carve-out is withdrawn — the tool's contract is now that it never
answers from no data, which is both simpler and base-free. And the Engineer chose
node recreation as the mechanism for the notes text, which v1 assumed the MCP could
patch in place.

Validation also surfaced three gaps in v1's own reasoning (V3, V4, V5) that are
properties of the derivation strategy rather than of its implementation, so they are
resolved here rather than left to the Executor.

### Steps
- P2' (R1, R3a; supersedes P2): an empty row set returns `NO_RATE_DATA` with no
  exception. No base is referenced and no conversion is answered without data.
- P4' (R3; supersedes P4, resolves V3 and V4): `UNKNOWN_CURRENCY` is claimed only
  when the row set is authoritative about the requested code. It is authoritative
  when a base was derived and every fetched row is quoted against that base. If no
  row carried a base at all (V3), or the fetched rows carry more than one base (V4 —
  the table is mid-migration, and the previous base can never appear as a target so
  it cannot be recognised any other way), an unmatched code reports `NO_RATE_DATA`
  instead. The conservative direction is deliberate: reporting missing data for a
  real code is recoverable, telling a user their currency does not exist is not.
- P5' (R1, resolves V5): base selection orders rows by parsed timestamp rather than
  by string comparison, so a non-ISO `fetched_at` cannot silently select a superseded
  base. Rows with an unparseable timestamp sort last.
- P6' (R4; supersedes P6): the notes text is applied by removing and re-adding
  `Code - Compute Conversion` through MCP `update_workflow` — the only operation that
  accepts node notes — preserving name, type, typeVersion, position and parameters,
  and re-adding the inbound connection from `Data Table - Get Rate Rows` in the same
  atomic call. The node's id changes; nothing references it by id. The re-export
  (P7) therefore also carries a new node id, which is expected and not drift.
- P9 (R5, resolves V6): the `alwaysOutputData` paragraph in the chat-agent page is
  corrected — an empty result now yields `NO_RATE_DATA` only.

### Risks (amended)
- Recreating the node loses anything not carried over explicitly. The re-export diff
  (P7) must show only the intended field changes plus the node id, and the live
  checks must be re-run after recreation, not before.
- P4' widens `NO_RATE_DATA` at the expense of `UNKNOWN_CURRENCY` precision in states
  the table should not normally be in. Validation should confirm the ordinary
  single-base populated table still reports `UNKNOWN_CURRENCY` for an unknown code.
