# PLAN — 2026-08-08-2026-08-08-currency-rate-loader

## v1

### Scope decision (R4)
Data Table creation + Schedule Trigger only. No HTTP fetch / upsert-write nodes in
this task — a stub write would require credential and API-shape decisions (rate
limits, response schema) that belong to a follow-up task. A1/A2 are verifiable
without them: A1 via Data Table existence + column/unique-key check, A2 via JSON
inspection of the Schedule Trigger node.

### R1 — Data Table `currency_rates`
- Columns: `base_currency` (string), `target_currency` (string), `rate` (number),
  `fetched_at` (string, ISO-8601 UTC timestamp).
- Unique key: composite (`base_currency`, `target_currency`). n8n Data Tables do not
  enforce composite unique constraints natively as of the current node version, so
  uniqueness is an application-level convention documented in `docs/` (schema notes)
  rather than a DB-level constraint — Executor must record this trade-off in the
  node's `notes` or an accompanying doc, satisfying root CLAUDE.md "failure must never
  corrupt stored data" by making the convention explicit for a future upsert workflow.
- Row identity for future upserts: match on `base_currency` + `target_currency`
  before insert (out of scope to implement the match logic now per R4, but the schema
  must not block it later — no auto-increment-only key that would prevent lookup).

### R2/R3 — Schedule Trigger + reconfigurable time
Node: `Schedule Trigger - Daily FX Pull`, interval = days, triggerAtHour = 6,
triggerAtMinute = 0 (UTC), matching current n8n instance timezone config assumption
(must be verified/noted since Schedule Trigger honors the n8n instance timezone, not
literal UTC, unless instance TZ = UTC).

Options for reconfigurable schedule time (per R3), evaluated:
1. **Bare node parameter (recommended)** — leave `triggerAtHour`/`triggerAtMinute` as
   plain node parameters, no expression. Changing the time is a two-field edit in the
   node UI, no redeploy of other logic, no hidden indirection. Lowest complexity,
   matches "prefer built-ins" convention. Trade-off: must re-export JSON after edit
   per root CLAUDE.md Export Discipline.
2. **Env-driven via `$env`** — read hour/minute from environment variables
   (`FX_SCHEDULE_HOUR`, `FX_SCHEDULE_MINUTE`) referenced in the node's expression
   fields. Enables ops-level change without opening the editor, but Schedule Trigger
   cron/interval fields have partial expression support depending on n8n version —
   must be validated with `validate_node_config` before relying on it; adds a runtime
   dependency on `.env`/instance env vars being visible to the workflow.
3. **Cron string in a Set/Config node feeding a Cron-mode trigger** — centralizes the
   schedule value next to other config, but Schedule Trigger is normally the first
   node (no upstream input), so this requires restructuring the trigger into
   Cron-expression mode with the expression pulled from a static workflow variable —
   more moving parts for no real benefit at this task's scope.

Recommendation: Option 1 (bare parameter), with a `notes` field on the trigger node
stating the current value (06:00 UTC), that it depends on instance timezone, and
pointing to option 2 as the documented upgrade path if ops ever needs env-driven
control without editor access. This satisfies A3 (two documented options + a pick)
without over-engineering a single-trigger workflow.

### File/module impact
- New: `workflows/1-currency-rate-loader.json` (Schedule Trigger node only, per R4
  scope; Data Table is an n8n-side object, not exported JSON).
- New/updated: `docs/` note describing `currency_rates` schema and the
  application-level uniqueness convention (required to satisfy A1's "documented
  unique key" since Data Tables can't self-document a composite key).
- No changes to `.env` / `.env.example` (no new secrets needed for this scope).

### Risks
- Data Table composite-uniqueness is convention-only, not enforced — must be called
  out, not silently assumed enforced (would otherwise violate root CLAUDE.md "failure
  must never corrupt stored data" once a real upsert loader lands later).
- Schedule Trigger's "UTC" framing depends on n8n instance timezone setting; Executor
  must verify instance TZ (via node config / best-practices lookup) rather than assume.

### Sequencing
1. Create `currency_rates` Data Table with 4 columns.
2. Build `workflows/1-currency-rate-loader.json` with single Schedule Trigger node,
   06:00 daily, notes per above.
3. Write schema/uniqueness-convention note in `docs/`.
4. Validator checks A1–A4.
