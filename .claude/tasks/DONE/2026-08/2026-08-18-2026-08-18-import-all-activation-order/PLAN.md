# PLAN — 2026-08-18-2026-08-18-import-all-activation-order
plan_version: 1

## Root cause (R1)
`scripts/import_workflow.sh` couples import+activate into one call per file;
`import-all` invokes it once per file in `for f in workflows/*.json` (alphabetical)
order with no awareness of cross-workflow references. `ai-chat-currency-agent.json`
has two `executeWorkflow` nodes with `workflowId.value = w5dvcvpZ5b9AVTLC`
(error-logger) plus a self-referencing `toolWorkflow` node
(`workflowId.value = bLflLYfGzORWkjJV`, its own id). Alphabetically it activates
before `error-logger.json` is even imported, so n8n's publish-time reference
check fails.

## Strategy (R2/A2)
Split "import" from "activate" and insert a dependency-ordering step between them,
driven by data already in the JSON (`workflowId.value` on `executeWorkflow` /
`toolWorkflow` nodes), not by filename order.

1. Import phase (all files, any order): CLI-import every `workflows/*.json`
   without activating. Import is idempotent/order-independent — n8n upserts by
   the file's own `id`, and a workflow's nodes can reference another workflow's
   id before that workflow exists in the DB (it's just a stored id string until
   activation-time validation runs).
2. Dependency-order computation: for each workflow file, extract the set of
   `workflowId.value` referenced by its `executeWorkflow`/`toolWorkflow` nodes,
   drop any reference equal to the file's own top-level `id` (self-reference,
   e.g. the `convert_currency` tool node — not a real ordering dependency), and
   build a directed graph file -> referenced-file. Topologically sort; a file
   with no unresolved dependencies (including one with zero references) is
   eligible to activate first.
3. Activate phase: activate files in topological order (dependency-free files
   first). Only files whose JSON has top-level `"active": true` get an activate
   call, same as today.
4. Cycle guard: if the graph has a cycle among distinct files (not counting
   self-references, which are already excluded), fail loudly and name the
   cycle — n8n cannot publish a genuine mutual-dependency pair either, so this
   is a real error to surface, not something to silently work around.

## File impact
- `scripts/import_workflow.sh`: remove the embedded activation block; it becomes
  import-only (CLI `import:workflow`, id-field precondition check unchanged).
  Keep it independently invocable for `make import FILE=...`, but that target
  now needs to also activate — see next point.
- New `scripts/activate_workflow.sh`: takes a filename, reads its `id` and
  `active` field, does the existing Public API `POST /workflows/:id/activate`
  call (moved verbatim from the current `import_workflow.sh`) including its
  401/non-2xx error handling. Reused by both `make import` (single file) and
  `make import-all`.
- New `scripts/order_workflows.py`: pure function over `workflows/*.json` ->
  topologically sorted filename list, implementing step 2's graph/self-reference
  logic and step 4's cycle detection (non-zero exit + cycle members on stderr).
  No n8n/API calls — file-system only, so it's independently testable.
- `Makefile`:
  - `import` (single file, A3): calls `import_workflow.sh` then
    `activate_workflow.sh` for that one file — same net behavior as today,
    now composed from two scripts instead of one.
  - `import-all`: (a) loop `import_workflow.sh` over every file, skipping
    `n8n-credentials-import.json` as today, in any order; (b) run
    `order_workflows.py` to get the activation order; (c) loop
    `activate_workflow.sh` over that ordered list.

## Risks
- A workflow could reference a sub-workflow that isn't in `workflows/` at all
  (typo'd id, or a workflow deliberately excluded from export). `order_workflows.py`
  should treat an unresolvable reference as "no ordering constraint from this
  edge" (log a warning) rather than fail the whole import — activation-time
  will surface the real n8n error if the reference is genuinely broken, same
  as today's behavior for any other activation failure.
- Splitting one script into three increases surface area; mitigate by keeping
  `activate_workflow.sh`'s API-call logic a verbatim move (no behavior change)
  and giving `order_workflows.py` no side effects (safe to run standalone for
  debugging, e.g. `python3 scripts/order_workflows.py` prints the computed
  order).

## Sequencing
1. Executor extracts activation logic out of `import_workflow.sh` into
   `activate_workflow.sh`.
2. Executor writes `order_workflows.py` (graph build, self-ref filter, topo
   sort, cycle detection).
3. Executor rewires `Makefile` `import` and `import-all` targets per File
   impact above.
4. Executor runs `make import-all` against the running Docker stand end-to-end
   (A1) and captures output in EXEC.md.
5. Validator re-runs `make import-all` independently (or inspects EXEC.md
   evidence + reads the three scripts/Makefile) against R1/R2/A1-A3.
