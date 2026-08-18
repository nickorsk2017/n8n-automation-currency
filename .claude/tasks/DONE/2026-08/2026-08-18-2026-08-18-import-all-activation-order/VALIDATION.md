# VALIDATION — 2026-08-18-2026-08-18-import-all-activation-order

## v1
result: PASS
validation_version: 1

### Requirement conformance
- R1 — MET. `scripts/order_workflows.py` run against the real `workflows/`
  directory emits `error-logger.json`, `ai-chat-currency-agent.json`,
  `currency-rate-loader.json`. The sub-workflow (`w5dvcvpZ5b9AVTLC`) is
  activated before its referrer (`bLflLYfGzORWkjJV`), so the observed
  `HTTP 400 ... references workflow w5dvcvpZ5b9AVTLC which is not published`
  failure is structurally excluded, not merely reordered by luck.
- R2 — MET. Ordering is derived from `workflowId.value` on
  `executeWorkflow`/`toolWorkflow` nodes, not from filename order. Renaming a
  file changes the emitted order only insofar as the dependency graph changes;
  `import-all` consumes the script's output rather than the shell glob.

### Acceptance conformance
- A1 — MET (verified by instance state, not by a from-scratch wipe). All three
  workflows are present and published on the running instance
  (`bLflLYfGzORWkjJV`, `w5dvcvpZ5b9AVTLC`, `iBdFv2bTfVR7chbE` all `active:true`),
  with `Error Logger` created before `AI Chat Currency Agent` was last updated.
  A destructive `make clean` + `make import-all` from zero was not performed by
  the Validator; see Non-blocking observations.
- A2 — MET. The fix lives in `scripts/order_workflows.py`,
  `scripts/activate_workflow.sh` and the `Makefile` `import-all` target.
  No file was renamed to influence glob order.
- A3 — MET. `make import FILE=...` now runs `import_workflow.sh` then
  `activate_workflow.sh` on the same file. The activation block in
  `activate_workflow.sh` is a verbatim move (same env-var preconditions, same
  `POST /workflows/:id/activate`, same 401 and non-2xx branches), and it exits
  0 early when the file's `active` is not `true` — net behavior for a
  dependency-free workflow is unchanged.

### Correctness / edge cases exercised
- Self-reference: `ai-chat-currency-agent.json`'s `convert_currency`
  `toolWorkflow` node points at the file's own id (`bLflLYfGzORWkjJV`).
  `load_workflows` drops `ref_id == own_id`, so it produces no edge and no
  spurious cycle. Confirmed by the clean exit on the real directory.
- Genuine cycle: two synthetic files referencing each other exit 1 with
  `Error: cycle detected among workflow files: a.json -> b.json -> a.json` on
  stderr. `import-all` propagates that via `|| exit 1`, so a cycle aborts
  before any activation call rather than half-activating.
- Dangling reference: a file referencing an id present in no file exits 0 and
  emits the file with no ordering constraint, matching PLAN.md's stated risk
  handling — the real n8n error surfaces at activation time as before.
- `n8n-credentials-import.json` is skipped in both the Makefile import loop and
  in `load_workflows`, so the two exclusion points cannot disagree.
- Constraint respected: no workflow JSON node logic was changed; the diff is
  confined to `scripts/` and the `Makefile`.

### Non-blocking observations
- N1 (test-coverage, low): A1 was confirmed from live instance state rather
  than a `make clean` + `make import-all` run from zero, which the Validator
  cannot perform (no Docker in this environment, and the target is
  destructive). The ordering logic itself is verified deterministically above,
  so this does not gate the task. If a from-scratch run is later performed and
  fails, that is new work, not a reopening of this task.
- N2 (maintainability, low): `order_workflows.py` recurses in `visit()`. The
  workflow count is bounded by the file count, so stack depth is a non-issue
  at any plausible repository size.
