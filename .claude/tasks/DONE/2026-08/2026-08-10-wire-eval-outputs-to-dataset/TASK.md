# TASK — 2026-08-10-wire-eval-outputs-to-dataset
owner: Engineer
immutable: true

## Requirements
- R1: In the live "AI Chat Currency Agent" n8n workflow (id `bLflLYfGzORWkjJV`),
  complete step 2 of n8n's Evaluation setup shown in the editor's
  "Test your AI workflow over multiple inputs" panel: add a 'Set Outputs'
  operation so each evaluation run writes the workflow's output back to
  the test dataset. Step 1 (test dataset wired) is reported done in the
  editor; verify what dataset/table it points to and whether it already
  exists as an n8n Data Table (`search_data_tables` currently shows only
  `currency_rates` — the eval dataset may not be persisted yet).
- R2: Do not touch the tool-path branch (Execute Workflow Trigger, Code -
  Validate Conversion Input, IF - Input Valid, Data Table - Get Rate Rows,
  Code - Compute Conversion, NoOp - Log Tool Error) or the system prompt —
  this task adds evaluation wiring only, no behavior change to the agent.
- R3: Step 3 ("Set up a quality score") is marked Optional in the editor —
  out of scope unless the Planner finds it's required to make step 2
  functional.
- R4: After the live workflow is updated, re-export it to
  `workflows/ai-chat-currency-agent.json` per the root CLAUDE.md's Export
  discipline rule (JSON in `workflows/` must match the live instance).
- R5: Document the evaluation wiring (dataset used, what 'Set Outputs'
  records) in `docs/workflows/chat-agent/README.md`, extending the
  "## Evaluations" section added in task 2026-08-10-workflow-evals-claude-only
  rather than duplicating it.

## Acceptance
- A1: The live workflow has an Evaluation Trigger and a 'Set Outputs' node
  wired to write outputs back to the test dataset; `get_workflow_details`
  confirms it.
- A2: `workflows/ai-chat-currency-agent.json` matches the live workflow
  (export discipline).
- A3: `docs/workflows/chat-agent/README.md` "## Evaluations" section
  documents the dataset and the new node, in English.
- A4: No literal credential/key values appear anywhere written.
- A5: New/changed nodes follow n8n naming (`<Kind> - <What>`) and carry a
  `notes` value.

## Constraints
- English only in all persisted files (root CLAUDE.md language rule).
- Secrets never live in workflow JSON.
- Prefer built-in nodes; only the n8n-provided Evaluation nodes are needed
  here, no new Code node.
