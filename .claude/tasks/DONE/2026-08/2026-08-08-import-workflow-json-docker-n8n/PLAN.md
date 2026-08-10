# PLAN — 2026-08-08-import-workflow-json-docker-n8n

## v1

### Context
`docker-compose.yml` already bind-mounts the repo's `workflows/` directory into
the container at `/home/node/.n8n/workflows` (read/write, host path visible
container-side under the same filenames). This means no `docker cp` step is
needed for import: any file in `workflows/*.json` is already reachable inside
the container at `/home/node/.n8n/workflows/<file>.json`. Import can go straight
through the n8n CLI (`n8n import:workflow --input=<path>`) via `docker compose
exec`.

### Design
- New script: `.claude/scripts/import_workflow.sh`
  - Usage: `./.claude/scripts/import_workflow.sh <workflow-file-in-workflows-dir>`
    e.g. `./.claude/scripts/import_workflow.sh 1-currency-rate-loader.json`
  - Behavior:
    1. Validate exactly one argument given; fail with usage message otherwise.
    2. Validate the file exists under `workflows/<arg>` on the host (fail fast
       with a clear error before touching Docker).
    3. Run `docker compose exec n8n n8n import:workflow
       --input=/home/node/.n8n/workflows/<arg>`.
    4. Propagate the n8n CLI's exit code.
  - No secret handling of any kind — the script only ever passes a filename; it
    never reads `.env` or embeds credential values, satisfying R3/A3. n8n
    resolves credentials by reference (name/id) already present in the JSON,
    same as documented in README's Setup section for the loader workflow.
- New `Makefile` target `import`: `import: ## Import a workflow JSON into the
  running n8n container (usage: make import FILE=1-currency-rate-loader.json)`
  wrapping `./.claude/scripts/import_workflow.sh $(FILE)`, consistent with the
  existing `up`/`down`/`restart`/`logs`/`ps` targets style (`.PHONY`, `##` help
  comment).
- Documentation: add a new subsection to README.md's **Setup** section (after
  the existing n8n instance bullet), "Importing a workflow", describing:
  `make import FILE=<name>.json` (or the raw script call), the prerequisite
  that the stack must already be running (`make up`), and that this is the
  inverse of the manual "export after editing" step already mandated by root
  CLAUDE.md's Export discipline section.

### Read/Write footprint
- Write: `.claude/scripts/import_workflow.sh` (new), `Makefile` (add target),
  `README.md` (Setup section addition).
- No changes to `workflows/*.json`, `docker-compose.yml`, or `.env*`.

### Verification (for Validator/Engineer)
- `make import FILE=1-currency-rate-loader.json` against a running `make up`
  stack imports without error; confirm via n8n UI or
  `docker compose exec n8n n8n export:workflow --all --output=/tmp/roundtrip`
  showing the workflow present.
- `grep -R` for API-key-shaped strings in the new script/docs turns up nothing
  (R3/A3).
- Script rejects missing/invalid filename with a non-zero exit and clear
  message (no silent no-op).

## v2 (addresses STATE.yaml open_issues: ISSUE-1)

### Change from v1
Move the script out of `.claude/scripts/` (harness-only per root CLAUDE.md
Repository layout) into a new top-level `scripts/` directory, which holds
project-facing operational tooling (distinct from `.claude/scripts/`, which
stays CI/harness-only, e.g. `ci_check.py`).

### Design (delta only — rest of v1 Design stands)
- New script path: `scripts/import_workflow.sh` (was
  `.claude/scripts/import_workflow.sh`). Same content/behavior as v1 (arg
  validation, host-file existence check, `docker compose exec n8n n8n
  import:workflow --input=/home/node/.n8n/workflows/<file>`, no secret
  handling) — only its location and its own internal `REPO_ROOT` resolution
  (one `..` instead of two, since it now sits one level under repo root
  instead of two) change.
- `Makefile` `import` target updated to call `scripts/import_workflow.sh`
  instead of `.claude/scripts/import_workflow.sh`.
- `README.md` "Importing a workflow" bullet updated to reference
  `scripts/import_workflow.sh` instead of the old path.
- `.claude/scripts/import_workflow.sh` (v1 artifact) is removed as part of
  this move — it must not be left behind as a stale duplicate.

### Read/Write footprint (v2, supersedes v1)
- Write: `scripts/import_workflow.sh` (new), remove
  `.claude/scripts/import_workflow.sh`, `Makefile` (path update), `README.md`
  (path update).
- No changes to `workflows/*.json`, `docker-compose.yml`, `.env*`.

### Verification (for Validator/Engineer, supersedes v1)
- Same as v1's Verification section, plus: confirm
  `.claude/scripts/import_workflow.sh` no longer exists (old path fully
  retired, not just duplicated) and `scripts/import_workflow.sh` is
  executable and referenced consistently in both `Makefile` and `README.md`.
