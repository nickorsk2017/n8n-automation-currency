# PLAN — 2026-08-09-wf1-error-logging-timezone

## v1

### Problem
`NoOp - Log Loader Error` is the convergence point for three failure branches
but has empty `parameters`. It therefore satisfies isolation (R4 holds today)
while satisfying nothing about logging: no record is written, and because a NoOp
completes normally, n8n marks the execution succeeded. A loader that has been
failing every morning for a week is indistinguishable, in the executions list,
from one that has been working.

### Design decision - two nodes replace the NoOp
Error path becomes:

    (3 failure branches) -> Code - Build Error Record -> Stop and Error - Fail Loader Run

Why a Code node here, given root CLAUDE.md prefers built-ins. The three inbound
branches deliver structurally different items: the HTTP error output carries
n8n's error shape, the `IF - Response OK` false branch carries the raw API body,
and the `IF - Rows Valid` false branch carries `{ rows: [...] }`. Classifying
which failure occurred requires conditional inspection of the incoming item,
which a Set node cannot express - this is the "validation rules" exemption the
root convention already allows. The alternative, three separate Set nodes (one
per branch), would state the failure statically but triples the node count and
duplicates the record shape three times; rejected as worse on both counts.

Why `Stop and Error` rather than an errors Data Table. R3 asks only for the run
to be visibly failed. `Stop and Error` throws, so the execution turns red in the
executions list and the structured record from the preceding Code node is
visible as that node's output. A persisted `loader_errors` table would give a
queryable audit trail across runs, but it is a schema change and a new write
path - out of scope here, and recorded as a future improvement instead.

Why the throw cannot corrupt data (R4). `Stop and Error` sits on the error
branch only. It has no outgoing connection, and no error-path node connects to
`Data Table - Upsert Rate Row`. The guard against partial writes remains
`IF - Rows Valid`, which is unchanged and still runs before the first write.

### Error record shape
- `failure_stage`  HTTP_FETCH / API_RESPONSE / ROW_VALIDATION, derived from item shape
- `error_message`  n8n error message, or a written explanation per stage
- `base_currency`  from `$('Set - Loader Config')`, guarded; it always runs before every failure point
- `failed_at`      ISO timestamp at classification time

Classification order matters: test for the n8n error shape first (it is the only
branch carrying `error`/`message`), then for absence of `rows` (API_RESPONSE,
since `Code - Rates To Rows` has not run on that branch), and treat the
remainder as ROW_VALIDATION. This ordering is total - every inbound item lands
in exactly one stage.

### Timezone (R5)
n8n resolves Schedule Trigger times against the instance timezone, which
defaults to America/New_York, not UTC. It is instance configuration, not a node
parameter. Add `GENERIC_TIMEZONE=UTC` (n8n's scheduling timezone) and `TZ=UTC`
(container clock, so logs and `new Date()` agree) to docker-compose.yml as
explicit `environment` entries rather than to `.env`, because these are
non-secret operational settings that must be identical on every stand - putting
them in the gitignored `.env` would make correct behaviour depend on a file no
one else receives. The Schedule Trigger note is then rewritten to state 06:00
UTC as a fact rather than a caveat.

### Files
- `workflows/1-currency-rate-loader.json` - replace one node with two, rewire
  three connections, update the Schedule Trigger note.
- `docker-compose.yml` - add the two environment variables.

### Risks
- Deleting the NoOp orphans three connections if they are not all rewired ->
  Validator must confirm zero remaining references to `NoOp - Log Loader Error`.
- `Stop and Error` on the HTTP branch means a freecurrencyapi outage now
  produces a red execution. That is the intent (R3), but it is a visible
  behaviour change worth stating in the docs.

STATE: stage=PLANNED, next_actor=Executor, plan_version=1

## v2 — amendment to R5 (raised during execution)

v1 pinned the timezone only in docker-compose.yml. That is necessary but not
sufficient: it fixes the self-hosted Docker stand and does nothing for the n8n
Cloud dev stand, where docker-compose does not apply and the instance timezone
is not ours to set. The exported workflow would then mean 06:00 UTC on one stand
and 06:00 America/New_York on the other - the same file, two behaviours.

Amendment: also set the workflow-level setting `settings.timezone = "UTC"` in
workflows/1-currency-rate-loader.json. n8n resolves a Schedule Trigger against
the workflow timezone when one is set, falling back to the instance timezone
otherwise, so pinning it in the exported file makes 06:00 UTC a property of the
workflow itself and therefore portable across stands. docker-compose.yml keeps
GENERIC_TIMEZONE/TZ so the container clock and any future workflow agree by
default.

Consequence for acceptance: A4 is satisfied by the workflow setting plus the
compose variables together, not by compose alone.

STATE: stage=PLANNED, next_actor=Executor, plan_version=2
