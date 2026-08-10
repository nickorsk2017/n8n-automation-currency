# TASK — 2026-08-09-workflow-export-sync
owner: Engineer
immutable: true

## Requirements
- R1: Close the one-directional sync gap. `scripts/import_workflow.sh` and
  `make import` push a repo file into the Docker stand, but there is no
  supported way to pull the other direction, so the "Export discipline" section
  of root CLAUDE.md ("after changing a workflow in the n8n editor, re-export it
  to the matching file") is a rule with no tooling behind it. Add
  `scripts/export_workflow.sh` and a `make export` target that writes a
  workflow from the running Docker container back into `workflows/`.
- R2: Add a drift check that reports whether `workflows/*.json` still matches
  what the instance actually holds, without modifying either side. This is the
  mechanical form of the same discipline: an editor change that was never
  exported should be detectable by running a command, not by someone
  remembering.
- R3: Fix the workflow id drift found during the previous task. The exported
  `workflows/1-currency-rate-loader.json` carries id `OgOk0TrsiV3xsNv9` while
  the live workflow is `iBdFv2bTfVR7chbE`. Because `n8n import:workflow`
  upserts by the file's own id, importing the file today would create a second,
  duplicate loader rather than updating the existing one.
  `workflows/2-ai-chat-currency-agent.json` is already consistent
  (`bLflLYfGzORWkjJV`) and must stay that way.
- R4: Document which stand each direction serves, since the repo spans two:
  the Docker stand (CLI-reachable, covered by these scripts) and the n8n Cloud
  dev stand (not CLI-reachable; reached through the n8n MCP on request).

## Acceptance
- A1: `scripts/export_workflow.sh` exists, is executable, refuses an unknown or
  missing workflow id with a readable message rather than a raw CLI error, and
  writes pretty-printed JSON to `workflows/<file>`.
- A2: `make export` and `make diff` are present in `make help` output with
  usage strings matching the existing `make import` style.
- A3: `workflows/1-currency-rate-loader.json` has top-level id
  `iBdFv2bTfVR7chbE`; `workflows/2-ai-chat-currency-agent.json` still has
  `bLflLYfGzORWkjJV`; both remain valid JSON with unchanged node counts.
- A4: The drift check reports a clean result for a file that matches and a
  non-zero exit for one that does not, demonstrated on a real comparison.
- A5: No secret values introduced into any script or workflow file.

## Constraints
- Touches scripts/export_workflow.sh (new), Makefile,
  workflows/1-currency-rate-loader.json -> MEDIUM.
- Scripts must not read `.env` or handle credential values, matching the
  precedent set by scripts/import_workflow.sh.
- The Docker stand may not be running in every environment; the scripts must
  fail with a clear message rather than a stack trace when it is not.
