# VALIDATION — 2026-08-08-fix-import-sqlite-constraint-id

## v1 (against PLAN.md v1 / EXEC.md v1)

### Requirement/acceptance check
- R1 (fix import): root cause (missing top-level `id`, CLI upserts by `id`
  rather than generating one) is well-supported by cited sources and matches
  the exact observed error. `git diff --stat` confirms the JSON fix is a
  single added line; `python3 -c` confirms the file is still valid JSON with
  `id` present. Pre-flight check in `scripts/import_workflow.sh` correctly
  parses `$HOST_PATH` (the same variable already validated for existence)
  and exits 1 with a specific message before any `docker compose exec` call
  — verified by both a positive run (valid file reaches the docker line) and
  a negative run (file without `id` rejected cleanly) in EXEC.md. OK.
- A1 (live import succeeds): **not verified** — no Docker daemon/binary in
  this sandbox, unchanged limitation from the prior task. Flagging as
  non-blocking manual follow-up for the Engineer, same rationale as before:
  this is a sandbox environment constraint, not something addressable from
  within the harness, and the fix's correctness is otherwise fully
  supported by root-cause research + static/dry-run verification.
- A2 (no business-logic change): `git diff workflows/1-currency-rate-loader.json`
  shows exactly one line added (`"id": "..."`), nothing else touched. OK.
- A3 (documented for future exports): README "Importing a workflow" bullet
  now explains the `id` requirement and that it persists automatically on
  re-export. OK.
- R3/A3 continuity (no secrets): `grep` for secret-shaped strings across all
  changed files — no matches. Script still never reads `.env` or credential
  values. OK.

### Verdict
status: PASS
open_issues: none

Manual follow-up (non-blocking, for Engineer, carried over and now
narrower in scope): re-run `make import FILE=1-currency-rate-loader.json`
against a locally running `make up` stack to confirm the SQLITE_CONSTRAINT
error is actually gone end-to-end — this could not be executed inside the
harness sandbox (no Docker at all available there).
