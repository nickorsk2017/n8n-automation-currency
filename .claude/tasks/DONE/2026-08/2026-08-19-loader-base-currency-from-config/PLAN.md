# PLAN — 2026-08-19-loader-base-currency-from-config

## v1

### Decision 1 — where the value lives
New Data Table `config`, key/value shaped: columns `config_key` (string),
`config_value` (string); the base currency is the row `config_key = base_currency`.
Rejected: a single-row table with one `base_currency` column — it forces a new
column (schema change + provisioning change) for every future loader setting,
while key/value absorbs them as rows. Rejected: reading the base from
`currency_rates` — that table is the loader's output, so the first run of a fresh
stand would have nothing to read (R3).
`config` is deliberately not workflow-scoped in name: it is provisioned by the same
setup path as the other tables and can hold settings for either workflow later.

### Decision 2 — where the default lives
The default is seeded data, not workflow logic: provisioning writes the
`base_currency` row when it is absent, and the workflow never substitutes a
currency of its own (R4, R6). Seeding is skipped when the row already exists, so an
operator's edit survives re-provisioning (R5). The seeded value comes from an
optional `.env` variable, defaulting to USD inside the provisioning script — the
one place a literal is permitted.
Rejected: a default inside the workflow (expression fallback / Set node) — that is
the hardcode R4 forbids and would mask a mis-provisioned stand by silently loading
the wrong base.

### Decision 3 — loader graph
`Set - Loader Config` is deleted (R1) and replaced between the trigger and the HTTP
request by:
1. `Data Table - Get Base Currency Config` — row/get against `config`
   (resource locator `mode: "name"`, per root CLAUDE.md), filtered to the
   `base_currency` key, single row, `alwaysOutputData` so a missing row yields an
   item rather than an empty branch that would silently end the run.
2. `IF - Base Currency Configured` — true output continues to the HTTP request;
   false output goes to the existing `Code - Build Error Record`, reusing the
   loader's established error path instead of adding a second one (R6).
The three consumers (HTTP query parameter, `Code - Rates To Rows`,
`Code - Build Error Record`) reference the config-read node by name, exactly as
they referenced the Set node (R2). No new Set node is introduced — that would
re-create what R1 removes.
Downstream nodes and connections from the HTTP request onward are untouched (A1).

### Decision 4 — error classification stays total
`Code - Build Error Record` currently classifies three branches by item shape; the
config branch's item is shape-ambiguous with the API_RESPONSE branch. Classification
therefore tests the config value first: an absent or blank value can only mean the
new branch fired, because the HTTP request cannot have run without it. New stage
label `CONFIG`, ordered before the existing three (A5).

### Impact map
- `workflows/currency-rate-loader.json` — nodes, connections, notes (R1, R2, R4).
- `scripts/create_data_table.sh` — provision `config` + seed default row idempotently (R5).
- `.env.example` — optional base-currency variable, documented as defaulting to USD.
- `Makefile` — `setup-data-table` / `setup` help text names the third table; operational
  note on changing the base currency lives here per root CLAUDE.md.
- `docs/workflows/rate-loader/` — config table schema, default, how to change the base;
  remove `Set - Loader Config` from prose (A6).
- `docs/architecture.md`, `README.md` — only if either names the Set node or lists the
  data tables; links checked mechanically (A6).

### Risks
- R-1 (blocking): the n8n Public API may expose no row-level endpoint for data tables
  on this version, leaving no scripted way to seed the default. The Executor verifies
  the row endpoints against the running stand before writing the script; if none
  exists, halt and escalate rather than substituting a workflow-side default, which
  would violate R4/R6.
- R-2: the config read is a per-run dependency the loader did not have — the stand
  must be provisioned before import for the first run to succeed. Accepted: `make
  setup` already precedes `make import` and now provisions this table too.
- R-3: `Code - Build Error Record` and the chat agent both reason about base currency;
  only the loader is in scope. Validator confirms `ai-chat-currency-agent.json` is
  byte-unchanged.

### Sequence
1. Verify data-table row endpoints on the running stand (R-1); record findings.
2. Extend `create_data_table.sh` (+ `.env.example`) — table, then conditional seed.
3. Rewrite the loader's head: delete Set node, add the two nodes, rewire connections.
4. Repoint the three consumers and extend the error classifier.
5. Re-export from the editor per Export discipline; confirm the file matches the run.
6. Run: fresh stand (A2), base changed in table only (A3), re-provision (A4), row
   removed (A5).
7. Docs + Makefile text; check every link resolves.
