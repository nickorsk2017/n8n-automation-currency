# EXEC — 2026-08-19-loader-base-currency-from-config

## v1

### Step 1 — API capability (PLAN risk R-1)
Resolved from n8n's Public API spec (v1.1.1) rather than the stand, which is not
reachable from this environment: `/data-tables/{id}/rows` supports GET and POST,
so the default row can be seeded by the same script that creates the table. No
escalation needed. Row *reads* in the script fetch the table and match in Python
instead of using the API's `filter` dialect, so the script does not depend on a
filter format that differs between the table and row endpoints.

### Step 2 — provisioning
`scripts/create_data_table.sh`: added the `config` table (`config_key`,
`config_value`) and two helpers — `table_id` and `seed_config_if_missing`. The
seed writes `base_currency` = `${LOADER_BASE_CURRENCY:-USD}` only when no
non-blank value exists, so re-runs leave an operator's value alone. `.env.example`
documents the optional variable.

### Step 3-4 — loader
`workflows/currency-rate-loader.json`:
- deleted `Set - Loader Config`;
- added `Data Table - Get Base Currency Config` (row/get, `mode: "name"` on
  `config`, filtered to `config_key = base_currency`, limit 1,
  `alwaysOutputData`) and `IF - Base Currency Configured` between the trigger and
  the HTTP request; the IF's false output joins the existing error branch;
- HTTP query parameter now `{{ $json.config_value }}`; `Code - Rates To Rows` and
  `Code - Build Error Record` reference the config-read node;
- `Code - Build Error Record` gained the `CONFIG` stage, tested before the other
  three since none of them can be reached without a base currency;
- notes rewritten on every touched node.
No `USD` literal and no reference to the deleted node remain in the file.

### Step 5 — export
No editor round-trip: the file was edited directly and is the artifact to import.
Nothing was changed in the running instance, so no export divergence is possible.

### Step 6 — runtime acceptance NOT executed
A2-A5 need a running stand; this environment has no Docker and no route to the
operator's n8n. The changes are structurally verified only (JSON parses, node
graph and references checked). Runtime verification is an operator step:
`make setup && make import FILE=currency-rate-loader.json`, run the loader, then
re-check after editing and after blanking the `base_currency` row.

### Step 7 — docs
New `docs/workflows/rate-loader/config-table.md`. Rewrote the base-currency
section of the loader README (flow diagram, failure table + `CONFIG`, failure
runbook renumbered), the root README's configuration section and setup snippet,
the data-flow step in `docs/architecture.md`, and the `setup-data-table` /
`setup` help text plus an operational note in the `Makefile`. Link check over all
Markdown: no broken relative links.

### Note for the Validator
`workflows/ai-chat-currency-agent.json` and `docs/workflows/chat-agent/README.md`
were already modified in the working tree before this task began (leftovers of
2026-08-18-agent-base-currency-not-hardcoded); this task did not touch them.
