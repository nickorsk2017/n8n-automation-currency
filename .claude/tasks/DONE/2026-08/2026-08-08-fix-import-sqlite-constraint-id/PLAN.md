# PLAN — 2026-08-08-fix-import-sqlite-constraint-id

## v1

### Root cause (confirmed via web research, cited in Sources)
n8n's `import:workflow` CLI imports/upserts a workflow **by the `id` field
already present in the JSON** — it does not generate one on insert. The
`workflow_entity.id` column is `NOT NULL` with no autoincrement/default for
this string-keyed table, so when the JSON has no top-level `id`, the
INSERT sent by the CLI omits the column entirely and SQLite rejects it:
`SQLITE_CONSTRAINT: NOT NULL constraint failed: workflow_entity.id`.
`workflows/1-currency-rate-loader.json`'s top-level keys are
`name, nodes, connections, pinData, settings, staticData, meta` — no `id`.
This is a known, long-standing n8n behavior/limitation (community reports
confirm CLI import keys strictly on a pre-existing `id`; the "Download"
button and `export:workflow` normally include one, but this file does not).
This is a data defect in the exported artifact, not a bug in
`scripts/import_workflow.sh` (which correctly invokes the CLI; nothing about
its own logic can supply a missing `id`).

### Design
- Add a top-level `"id"` field to `workflows/1-currency-rate-loader.json`:
  a 16-character alphanumeric string (matching n8n's own generated-ID shape,
  e.g. `nanoid()` output), inserted once and then treated as stable —
  future exports of this same workflow must re-export with this same `id`
  preserved (n8n's own "Download"/`export:workflow` will keep it once the
  live instance's workflow itself has it, which happens on first successful
  import).
- Harden `scripts/import_workflow.sh` with a pre-flight check: before
  invoking `docker compose exec`, parse the target JSON (via `python3 -c
  json.load`, already relied on implicitly by the workflow-JSON convention —
  no new dependency, `python3` is a safe assumption in this project's
  existing tooling) and fail fast with a clear, specific error if the file
  has no top-level `id` key, rather than letting the opaque
  `SQLITE_CONSTRAINT` bubble up from inside the container. This directly
  serves R1 (import succeeds without an inscrutable SQL error) and guards
  against the same class of defect recurring for future workflow files
  (e.g. workflow 2, not yet built).
- Document the requirement in `README.md`'s existing "Importing a workflow"
  bullet: workflow JSON must include a top-level `id` for
  `import:workflow` to succeed; this is preserved automatically by
  re-exporting from a live instance (Export discipline in root `CLAUDE.md`),
  so it should only ever need fixing once per workflow, at first import.

### Read/Write footprint
- Write: `workflows/1-currency-rate-loader.json` (add `id` field only — no
  change to `nodes`/`connections`/business logic, satisfies A2).
- Write: `scripts/import_workflow.sh` (add pre-flight `id` check).
- Write: `README.md` ("Importing a workflow" bullet — add one sentence on
  the `id` requirement, satisfies A3).

### Verification (for Validator/Engineer)
- `python3 -c "import json; assert 'id' in json.load(open('workflows/1-currency-rate-loader.json'))"`
  passes.
- Script's new pre-flight check rejects a workflows-dir JSON file lacking
  `id` with a clear message and non-zero exit, without reaching
  `docker compose exec` (verifiable in-sandbox without Docker, same pattern
  used for the existing missing-file check).
- `grep` for secret-shaped strings across the changed files — still none
  (A2 continuity).
- A1 (live import succeeding) — Engineer verifies locally against a running
  `make up` stack; cannot run in the harness sandbox (no Docker daemon),
  same documented limitation as the prior task.

### Sources
- https://community.n8n.io/t/importing-workflows-with-cli-dont-keep-ids/6825
  (confirms CLI import keys on `id`; IDs must be present/stable across
  import cycles)
- https://github.com/n8n-io/n8n/issues/21210 and
  https://github.com/n8n-io/n8n/issues/23128 (related but distinct CLI
  import failure modes on recent n8n versions — foreign-key/webhook races,
  not this NOT NULL case; ruled out as the cause here since our JSON simply
  has no `id` at all)
