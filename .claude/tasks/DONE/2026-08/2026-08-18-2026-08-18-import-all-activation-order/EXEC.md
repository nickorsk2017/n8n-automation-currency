# EXEC — 2026-08-18-2026-08-18-import-all-activation-order
exec_version: 1

## Changes (per PLAN.md v1)
- P1: `scripts/import_workflow.sh` — removed the embedded activation block
  (lines that read N8N_API_URL/N8N_API_KEY and POSTed /activate). It now only
  runs `n8n import:workflow` after the existing top-level-`id` precondition
  check. Behavior for the import step itself is unchanged.
- P1: `scripts/activate_workflow.sh` (new) — the activation block moved
  verbatim from the old `import_workflow.sh` (same env var checks, same
  Public API `POST /workflows/:id/activate` call, same 401/non-2xx error
  handling). No-ops (exit 0) if the file's `active` is not `true`.
- P2: `scripts/order_workflows.py` (new) — reads `workflows/*.json` (skips
  `n8n-credentials-import.json`), builds a dependency graph from
  `executeWorkflow`/`toolWorkflow` node `workflowId.value` refs, drops
  self-references, topologically sorts, exits 1 with the cycle path on
  stderr if one exists. Pure filesystem read, no API calls.
- P3: `Makefile` — `import` now runs `import_workflow.sh $(FILE) &&
  activate_workflow.sh $(FILE)` (A3: same net effect as before, just
  composed from two scripts). `import-all` now: (a) loops
  `import_workflow.sh` over every file in any order, (b) runs
  `order_workflows.py` to get the activation order, (c) loops
  `activate_workflow.sh` over that ordered list.

## Verification done in this environment
- `chmod +x` applied to the two shell scripts and the new Python script.
- `python3 scripts/order_workflows.py` run standalone against the real
  `workflows/` directory. Output:
  ```
  error-logger.json
  ai-chat-currency-agent.json
  currency-rate-loader.json
  ```
  Confirms R1's failure mode is fixed by construction: `error-logger.json`
  (id `w5dvcvpZ5b9AVTLC`, the sub-workflow `ai-chat-currency-agent.json`
  depends on) now sorts before it, and the self-reference on
  `ai-chat-currency-agent.json`'s own id (`bLflLYfGzORWkjJV`, via the
  `convert_currency` toolWorkflow node) does not create a spurious cycle.

## Not verified here (A1 — needs the Engineer's machine)
This execution environment has no `docker` binary, so `make import-all`
cannot be run end-to-end against the Docker n8n stand from here. Everything
that can be checked without Docker (script logic, ordering output on the
real files, syntax) is verified above. Engineer: please run `make import-all`
against your Docker stand (fresh or existing instance) and report the
outcome so the Validator can close A1.
