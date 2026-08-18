# TASK — 2026-08-10-wire-loader-eval-outputs
owner: Engineer
immutable: true

## Requirements
- R1: The n8n editor's Evaluations tab for "Daily Currency Rate Loader"
  (`iBdFv2bTfVR7chbE`) shows step 1 ("Wire up a test dataset") checked
  and step 2 ("Write workflow outputs back to dataset") pending.
  `get_workflow_details` shows this is misleading the same way it was for
  the chat agent (task 2026-08-10-wire-eval-outputs-to-dataset): the live
  workflow already has two nodes — `When fetching a dataset row`
  (`n8n-nodes-base.evaluationTrigger`, `dataTableId` mode "list" with an
  **empty** value — not actually pointed at any dataset) and `Evaluation`
  (`n8n-nodes-base.evaluation`, `operation: setInputs`) — but neither is
  wired into the workflow's connections, and neither exists in the
  *active* published version, only in the draft. Step 1 is not really
  done. Planner must account for this before proposing step 2.
- R2: This workflow is a scheduled, non-AI batch loader (fetches FX rates
  from freecurrencyapi, transforms, and upserts into `currency_rates`) —
  unlike the chat agent, it has no natural-language answer to score for
  "correctness". Planner must decide what a test dataset and "output"
  even mean here (e.g. a fixed sample API response as input, and the
  transformed rows or thrown error as the recorded output) before wiring
  anything, and should say plainly if wiring n8n Evaluations onto this
  workflow is a good fit at all.
- R3: If the Planner concludes evaluation wiring is not a good fit for a
  deterministic scheduled loader, the two existing stub nodes
  (`When fetching a dataset row`, `Evaluation`) should be removed from the
  live workflow (they are currently orphaned/unconfigured clutter) rather
  than left half-wired, and that decision documented.
- R4: If wired, re-export to `workflows/currency-rate-loader.json`
  (Export discipline) and document in `docs/workflows/rate-loader/`.
- R5: Do not change the loader's actual fetch/transform/upsert/error
  logic — this task is only about the evaluation wiring question.

## Acceptance
- A1: A clear, written decision exists (in PLAN.md) on whether evaluation
  wiring fits this workflow, with reasoning grounded in R2.
- A2: The live workflow's evaluation-related nodes (existing stubs, plus
  anything newly added) are either fully configured and connected, or
  removed — no orphaned/half-configured nodes left on canvas either way.
- A3: If kept, `workflows/currency-rate-loader.json` matches the live
  workflow and the approach is documented in
  `docs/workflows/rate-loader/`. If removed, the exported JSON has no
  trace of them either.
- A4: No literal credential/key values in any changed file.
- A5: R5 preserved — loader logic nodes/connections unchanged.

## Constraints
- English only in all persisted files.
- Secrets never live in workflow JSON.
