# EXEC — 2026-08-08-import-workflow-json-docker-n8n

## v1 (implements PLAN.md v1)

### Changes
- Added `.claude/scripts/import_workflow.sh` (new, executable): validates a
  single filename argument, checks `workflows/<file>` exists on the host,
  then runs `docker compose exec n8n n8n import:workflow
  --input=/home/node/.n8n/workflows/<file>` (no `docker cp` — relies on the
  existing `workflows/` bind mount from `docker-compose.yml`). Never reads
  `.env` or any secret value.
- `Makefile`: added `.PHONY` entry and new `import` target — `make import
  FILE=<name>.json` — wrapping the script, styled consistently with existing
  `up`/`down`/`restart`/`logs`/`ps` targets (`##` help comment).
- `README.md`: added an "Importing a workflow" bullet to the Setup section
  (after the n8n instance bullet), documenting `make import FILE=...`,
  the bind-mount rationale, that it's the inverse of the Export discipline
  step in root `CLAUDE.md`, and that no secret is read or required.

### Verification performed (this sandbox — no Docker daemon available)
- `bash -n .claude/scripts/import_workflow.sh` — syntax OK.
- Ran script with 0 args -> usage message, exit 1.
- Ran script with a nonexistent filename -> clear error, exit 1 (fails fast,
  never reaches `docker compose exec`).
- `grep` for API-key-shaped strings across the new/changed files
  (script, Makefile, README) -> no matches (satisfies R3/A3).
- `make` recipe line under `import:` confirmed tab-indented (not spaces) via
  `cat -A`, so `make import` will invoke the script correctly.

### Not verified here (requires Engineer's local Docker environment)
- A1 (actual `make import FILE=1-currency-rate-loader.json` against a running
  `make up` stack, confirmed via n8n UI or an export round-trip) — this
  sandbox has no Docker daemon. Engineer/Validator should run this locally
  before closing the task.

### Read/Write footprint (matches PLAN.md v1)
- Wrote: `.claude/scripts/import_workflow.sh` (new), `Makefile` (added
  target), `README.md` (Setup section addition).
- No changes to `workflows/*.json`, `docker-compose.yml`, `.env*`.

## v2 (implements PLAN.md v2 — addresses ISSUE-1)

### Changes
- Added `scripts/import_workflow.sh` (new, executable, top-level `scripts/`
  dir) — same behavior as v1, `REPO_ROOT` resolution adjusted for its new
  depth (one `..` instead of two).
- Removed `.claude/scripts/import_workflow.sh` (v1 artifact) — deletion
  required an explicit Cowork file-delete permission grant (protected
  workspace path), obtained before removing.
- `Makefile`: `import` target now calls `scripts/import_workflow.sh`.
- `README.md`: "Importing a workflow" bullet now references
  `scripts/import_workflow.sh`.

### Verification performed
- `bash -n scripts/import_workflow.sh` — syntax OK.
- Ran with 0 args -> usage, exit 1; with nonexistent filename -> clear error,
  exit 1.
- `grep -rn` for the old `.claude/scripts/import_workflow.sh` path across
  Makefile/README/scripts -> no hits; only remaining references are in this
  task's own historical artifact versions (PLAN.md v1, EXEC.md v1,
  VALIDATION.md v1, LOG.md), which is expected and correct per Write
  Discipline (old version blocks are kept, not deleted).
- `.claude/scripts/import_workflow.sh` confirmed gone; `scripts/import_workflow.sh`
  confirmed present and executable.
- `cat -A Makefile` confirmed the `import:` recipe line is tab-indented.

### Not verified here (unchanged from v1 — requires Engineer's local Docker)
- A1: actual `make import FILE=1-currency-rate-loader.json` against a running
  `make up` stack — no Docker daemon in this sandbox.

### Read/Write footprint (v2, supersedes v1)
- Wrote: `scripts/import_workflow.sh` (new).
- Removed: `.claude/scripts/import_workflow.sh`.
- Wrote: `Makefile` (path update), `README.md` (path update).
