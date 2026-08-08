# PLAN — 2026-08-08-2026-08-08-provision-currency-rate-loader

## v1

### Order of operations
1. R3: `search_projects` (type=personal) to resolve target projectId. If the user
   has previously named a specific project in conversation, resolve that name
   instead; otherwise default to personal project per n8n MCP tool guidance.
2. R1: `search_data_tables(query: "currency_rates")` first — guard against
   duplicate creation if it already exists from a prior manual attempt. If absent,
   `create_data_table` with the 4 columns from docs/data-table-schema.md, exact
   names/types (base_currency:string, target_currency:string, rate:number,
   fetched_at:string).
3. R2: `get_sdk_reference` (full or "patterns"+"import" sections) ->
   `get_workflow_best_practices(technique: "scheduling")` ->
   `search_nodes(["schedule trigger"])` -> `get_node_types` for the resolved
   scheduleTrigger discriminator -> write SDK code reproducing the single node
   (interval=days, triggerAtHour=6, triggerAtMinute=0, notes text carried over
   verbatim from the repo JSON) -> `validate_workflow` -> on pass,
   `create_workflow_from_code` with name "1 - Daily Currency Rate Loader",
   projectId from step 1.
4. R4: `get_workflow_details` on the created workflow id; diff node type/params
   against `workflows/1-currency-rate-loader.json`. If SDK-generated JSON differs
   in substance (not just generated ids/positions), Executor overwrites the repo
   file with the live version to keep it authoritative.
5. R5 is a negative constraint — no action, just avoid credential-creation tools.

### Risk / rollback
- If `create_data_table` fails because a table with that name already exists
  under a different schema, Executor must NOT alter/drop the existing table —
  halt and record as an EXEC.md blocker for Validator to route back to Engineer
  (ambiguous state, needs human decision), rather than guessing intent.
- If `validate_workflow` fails, Executor iterates SDK code locally (not a
  Planner-level architecture change) until it passes, before ever calling
  `create_workflow_from_code`.
- Node IDs/positions in the live-created workflow will differ from the
  hand-written repo JSON's placeholder UUID/position — this is expected and NOT
  a R4 mismatch; only type/parameter/notes differences count.

### File/module impact
- No new repository files. `workflows/1-currency-rate-loader.json` is
  conditionally overwritten (R4) if the live SDK-built version differs
  substantively.
- Live n8n instance: +1 Data Table object, +1 Workflow object.

### Sequencing (Executor)
P1. search_projects -> resolve projectId.
P2. search_data_tables -> if absent, create_data_table (R1).
P3. get_sdk_reference, get_workflow_best_practices, search_nodes, get_node_types
    (R2 prep).
P4. Write SDK code, validate_workflow, create_workflow_from_code (R2).
P5. get_workflow_details, diff vs repo JSON, re-export if needed (R4).
P6. Write EXEC.md with tool-call summary and any diffs/blockers.
