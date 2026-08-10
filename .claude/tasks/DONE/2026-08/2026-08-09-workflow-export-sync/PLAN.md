# PLAN — 2026-08-09-workflow-export-sync

## v1

### Why this is the highest-value piece of tooling in the repo
Root CLAUDE.md already declares `workflows/*.json` the source of truth for
review and requires re-export after any editor change. Nothing enforces it, and
the cost of that was demonstrated concretely in the previous task: the loader's
file id had silently diverged from the live instance, which means the documented
recovery path (`make import`) would have produced a duplicate workflow rather
than restoring the real one. A rule that is only in prose is a rule that decays.

### Two stands, two directions - be explicit
The repo spans two n8n instances and they are not symmetric:

- **Docker stand** (docker-compose.yml, `n8n` CLI reachable via
  `docker compose exec`). Both directions are scriptable: `make import` pushes,
  `make export` pulls. This is the stand the scripts serve.
- **n8n Cloud dev stand** (`nickdevstartup.app.n8n.cloud`). No CLI access, so no
  shell script can reach it. Its pull direction is served by the n8n MCP on
  request - the "Claude + MCP" layer - not by a Makefile target.

Pretending one script covers both would be the wrong abstraction; R4 exists so
the docs state the split rather than leaving someone to discover it.

### Export design
`n8n export:workflow --id=<id> --output=<path>` writes inside the container.
`workflows/` is already bind-mounted at `/home/node/.n8n/workflows`, so writing
to the container path lands the file on the host with no `docker cp` - exactly
the trick `import_workflow.sh` already relies on, reused in reverse.

Two problems to handle:

1. **Formatting.** The CLI emits its own JSON layout, which would churn the diff
   on every export even when nothing changed. Post-process to a stable
   pretty-printed form so a diff shows semantic change only.
2. **Ownership of the filename.** Export is by id, but the repo names files by
   number and slug. The script therefore takes both: `<workflow-id> <file>`, and
   refuses to guess.

Preconditions checked with readable errors, following `import_workflow.sh`'s
precedent: container not running; unknown id (CLI exits non-zero and writes
nothing).

### Drift check design
`make diff FILE=... ID=...` exports to a temp path and compares against the repo
file, normalising both through the same pretty-printer so formatting differences
never register as drift. Exit 0 = in sync, exit 1 = drifted, with the difference printed.

Deliberately compares **semantic content**, not a byte hash: n8n rewrites
`versionId`, `updatedAt` and similar volatile fields on every save, and a hash
comparison would report drift constantly and be ignored within a week. Those
fields are stripped before comparison. This is the first, deterministic member
of the audit layer described in the README's future work - no LLM involved, no
false positives.

### Id drift (R3)
Set the loader file's id to the live `iBdFv2bTfVR7chbE`. Direction matters: the
live workflow is the one with real execution history, an active schedule and a
credential attached, so the file yields to the instance rather than the reverse.
The alternative - importing the file under its own id - would create a duplicate
and leave two loaders competing on the same schedule.

### Files
- `scripts/export_workflow.sh` (new, executable)
- `Makefile` - `export` and `diff` targets
- `workflows/1-currency-rate-loader.json` - id only

### Risks
- The Docker stand is not running in this session, so A4 cannot be demonstrated
  through the container. Mitigation: prove the comparison logic against a real
  pair of inputs (repo file vs the live workflow fetched through the MCP), which
  exercises the same normalise-and-compare path the script uses.

STATE: stage=PLANNED, next_actor=Executor, plan_version=1
