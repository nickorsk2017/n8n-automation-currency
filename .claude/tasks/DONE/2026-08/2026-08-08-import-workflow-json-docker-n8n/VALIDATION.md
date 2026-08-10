# VALIDATION — 2026-08-08-import-workflow-json-docker-n8n

## v1 (against PLAN.md v1 / EXEC.md v1)

### Findings

**FAIL — architecture issue: script placement conflicts with repository layout.**

Root `CLAUDE.md` (Repository layout) scopes `.claude/` explicitly as "the harness
(runner, role skills, hooks, task artifacts)" — a separate layer from the project's
own deliverables (`workflows/`, `docs/`, `screenshots/`, `README.md`). PLAN.md v1
placed the new operational script at `.claude/scripts/import_workflow.sh`, alongside
`.claude/scripts/ci_check.py` (a harness/CI script). But `import_workflow.sh` is a
project-facing deliverable — it's invoked by `make import`, documented in the
README's Setup section for anyone running this project, and has nothing to do with
task orchestration. Colocating it with harness internals:
- conflates two layers the root CLAAUDE.md deliberately separates,
- means a reader following "Repository layout" in root CLAUDE.md won't find it,
- risks the script being swept up in any future harness-only tooling change to
  `.claude/scripts/` (e.g. `ci_check.py` conventions) that has nothing to do with it.

TASK.md's own constraint left placement open ("Planner to decide placement") but did
not waive the repository-layout convention — the Planner's choice should have stayed
inside the existing layout (e.g. a top-level `scripts/` directory) rather than
introducing a new one under `.claude/`.

This is a design/placement decision, not an implementation bug — routing to Planner
per Failure Routing (`architecture` issues -> Planner, bump `plan_version`).

### Other checks (informational, not blocking — recheck after re-route)
- R3/A3 (no secrets): confirmed no secret-shaped strings in script/Makefile/README — OK.
- Script fail-fast behavior (usage / missing file -> exit 1): confirmed in EXEC.md — OK.
- A1 (actual import against running Docker n8n): not yet verified — sandbox has no
  Docker daemon; still open regardless of the architecture fix.

### Verdict
status: FAIL
open_issues:
- id: ISSUE-1
  type: architecture
  severity: medium
  ref: "PLAN.md v1 Design section — script placement `.claude/scripts/import_workflow.sh`; should live under a top-level `scripts/` directory per root CLAUDE.md Repository layout"

## v2 (against PLAN.md v2 / EXEC.md v2)

### ISSUE-1 re-check
`scripts/import_workflow.sh` now sits under top-level `scripts/`, separate
from `.claude/scripts/` (harness-only). Old path confirmed removed; Makefile
and README both reference the new path; no stale references outside this
task's own historical artifact versions. ISSUE-1 — resolved.

### Requirement/acceptance check
- R1/A1 (import command): `scripts/import_workflow.sh` uses
  `docker compose exec n8n n8n import:workflow --input=...` against the
  existing `workflows/` bind mount from `docker-compose.yml` (no `docker cp`
  needed — path traced and confirmed consistent between `HOST_PATH`
  resolution, the bind-mount target in `docker-compose.yml`, and
  `CONTAINER_PATH`). Static review confirms correctness: `REPO_ROOT`
  resolves one level up from `scripts/`, matching its new depth; `cd
  "$REPO_ROOT"` before `docker compose exec` ensures `docker-compose.yml` is
  found. **Live-Docker execution not verified** — no Docker daemon in this
  sandbox (unchanged limitation from v1, not a defect in the deliverable).
  Flagging as a manual-verification item for the Engineer rather than a
  blocking defect, since it is an environment constraint of the harness
  sandbox, not something either Planner or Executor can address from here.
- R2/A2 (docs): README "Importing a workflow" bullet present, describes
  command, arguments (`FILE=<name>.json`), and prerequisite (`make up`
  first). OK.
- R3/A3 (no secrets): `grep` for secret-shaped strings across
  `scripts/import_workflow.sh`, `Makefile`, `README.md` — no matches. Script
  never reads `.env` or any credential value. OK.
- Constraints: script placement now follows repository layout (top-level
  `scripts/`, harness untouched); reuses existing Docker/bind-mount setup
  from prior DONE tasks, no new Docker config introduced. OK.
- Fail-fast behavior (no args / missing file -> exit 1, no silent no-op):
  confirmed in EXEC.md v1 and v2. OK.

### Verdict
status: PASS
open_issues: none

Manual follow-up (non-blocking, for Engineer): run `make import
FILE=1-currency-rate-loader.json` against a locally running `make up` stack
once, to confirm the live n8n CLI invocation behaves as expected end-to-end —
this could not be executed inside the harness sandbox (no Docker daemon
available there).
