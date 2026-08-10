# EXEC — 2026-08-09-workflow-export-sync

## v1
Changed files:
- `scripts/export_workflow.sh` (new, executable) — `n8n export:workflow` inside
  the container writing to the bind-mounted `workflows/` path, then normalising
  the CLI's output to stable pretty-printed JSON. Guards: wrong arg count,
  container not running, unknown id, export claiming success without producing a
  file. Unwraps the single-element list some n8n versions emit.
- `scripts/check_workflow_drift.py` (new, executable) — semantic comparison of a
  repo file against an instance dump. Strips volatile top-level fields
  (`versionId`, `updatedAt`, `createdAt`, `triggerCount`, `meta`, `pinData`,
  `staticData`, ...) and per-node `position`/`id`. Compares id, name, settings,
  node set, per-node fields and connections. Exit 0 in sync / 1 drifted / 2
  usage error.
- `Makefile` — `export` and `drift` targets, both listed by `make help` with
  usage strings matching the existing `import` style. `drift` shuffles the repo
  file aside, exports into its place, moves the result to a temp path, restores
  the original and then compares — so the check never mutates the repo file even
  though export writes by filename.
- `workflows/1-currency-rate-loader.json` — id `OgOk0TrsiV3xsNv9` ->
  `iBdFv2bTfVR7chbE`.

The fetch step is deliberately not inside `check_workflow_drift.py`: it takes
two files, so the same comparison serves the Docker stand (fed by
export_workflow.sh) and the Cloud stand (fed from the n8n MCP), which have no
common transport.

### Evidence
Container-based export could not run here (no Docker stand in this session), so
the comparison logic was exercised directly against real inputs:

- **Control, identical inputs** — file vs itself: `in sync`, exit 0.
- **Simulated editor drift** — a copy of the live loader with the timezone
  changed to `America/New_York`, `Stop and Error - Fail Loader Run` renamed back
  to `NoOp - Log Loader Error`, and `Set - Loader Config`'s base currency changed
  to EUR. Result exit 1, reporting the settings change, the node present only in
  the repo file, the node present only on the instance, and
  `node 'Set - Loader Config' differs in parameters`. This is exactly the "edited
  in the UI, never re-exported" scenario.
- **Noise control** — a copy differing only in `versionId`, `updatedAt`, `meta`,
  `pinData`, every node `position` shifted by 999 and every node `id`
  regenerated: `in sync`, exit 0. The check does not cry wolf on n8n's own
  bookkeeping, which is the property that decides whether anyone keeps running
  it.

### Verification of R3
`workflows/1-currency-rate-loader.json` id is now `iBdFv2bTfVR7chbE`, matching
the live workflow updated in the previous task;
`workflows/2-ai-chat-currency-agent.json` still holds `bLflLYfGzORWkjJV`. Both
parse, with 10 and 11 nodes respectively.

Secret scan across `scripts/` and `workflows/`: no literal key values; the only
matches are prose in node notes and script comments stating that secrets are
never stored there.

STATE: stage=EXECUTED, next_actor=Validator, exec_version=1
