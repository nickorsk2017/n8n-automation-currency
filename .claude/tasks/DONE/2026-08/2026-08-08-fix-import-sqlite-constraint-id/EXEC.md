# EXEC — 2026-08-08-fix-import-sqlite-constraint-id

## v1 (implements PLAN.md v1)

### Changes
- `workflows/1-currency-rate-loader.json`: inserted a single top-level
  `"id": "OgOk0TrsiV3xsNv9"` line (16-char alphanumeric, generated via
  Python `secrets`) right after the opening brace, via a targeted line
  insert (not a JSON re-serialize) to avoid reformatting the rest of the
  file — `git diff` confirms exactly one line added, no other changes.
- `scripts/import_workflow.sh`: added a pre-flight check (after the
  existing file-existence check, before `docker compose exec`) that parses
  the target JSON with `python3 -c` and fails with a clear, specific error
  message + non-zero exit if `id` is missing, instead of letting the raw
  `SQLITE_CONSTRAINT` bubble up from inside the container.
- `README.md`: extended the existing "Importing a workflow" bullet with a
  sentence on the `id` requirement and the script's fail-fast behavior.

### Verification performed
- `python3 -c "'id' in json.load(...)"` — confirms `id` present and file
  still valid JSON after the edit.
- `git diff workflows/1-currency-rate-loader.json` — exactly one line
  added (`"id": "..."`), nothing else changed; satisfies A2 (no business
  logic change).
- `bash -n scripts/import_workflow.sh` — syntax OK.
- Ran script against the now-fixed `1-currency-rate-loader.json`: passes
  the file-existence and `id` checks, reaches the `docker compose exec`
  line (fails only with `exec: docker: not found`, since this sandbox has
  no Docker binary at all — expected and unrelated to the fix).
- Ran script against a throwaway file with no `id` (`workflows/__test_no_id.json`,
  created and removed within this verification step, never committed):
  rejected with the new clear error message, exit 1, before reaching
  `docker compose exec`.
- `grep` for secret-shaped strings across all changed files — no matches
  (A2/R3 continuity).

### Not verified here (unchanged limitation — requires Engineer's local Docker)
- A1: Engineer should re-run `make import FILE=1-currency-rate-loader.json`
  against a running `make up` stack to confirm the fix resolves the
  originally reported failure end-to-end. No Docker daemon or binary is
  available in this harness sandbox.

### Read/Write footprint (matches PLAN.md v1)
- Wrote: `workflows/1-currency-rate-loader.json` (added `id` field only).
- Wrote: `scripts/import_workflow.sh` (added pre-flight `id` check).
- Wrote: `README.md` (Importing a workflow bullet — added `id` note).
