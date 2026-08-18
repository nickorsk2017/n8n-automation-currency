# PLAN — 2026-08-10-wire-eval-outputs-to-dataset
# PLAN — 2026-08-10-wire-eval-outputs-to-dataset

## v1

### Fact-check against live state (R1)
`get_workflow_details` on the live "AI Chat Currency Agent" workflow shows
no Evaluation Trigger or Evaluation node exists today, and
`search_data_tables` shows only the `currency_rates` table — no eval
dataset table exists yet. The editor screenshot's "step 1 done" checkmark
does not match instance state (likely a stale/unsaved editor session or
generic UI chrome). Executor must not assume a dataset already exists;
step 1 is effectively also open, ahead of the requested step 2.

### Dataset (new)
A new Data Table, `chat_agent_eval_dataset`, columns `question` (string)
and `expected_answer` (string) — the minimum shape an Evaluation Trigger
needs as ground truth input, and small enough to seed by hand. Row content
(a handful of representative Q&A pairs covering a normal conversion, an
unknown currency, and the prompt-injection/off-topic refusal case) is an
Executor-level detail, not an architecture decision.

### Node additions — main chat branch only (R2 preserved)
Two nodes added to the live workflow, none of them touching the
tool-path branch (Execute Workflow Trigger / Validate / IF / Data Table -
Get Rate Rows / Compute Conversion / NoOp):

1. `Evaluation Trigger - Read Test Dataset`
   (`n8n-nodes-base.evaluationTrigger`, source=dataTable, pointed at
   `chat_agent_eval_dataset`). Feeds `AI Agent - Currency Assistant` the
   same way `Chat Trigger - Currency Agent Entry` does today — this makes
   the agent node fan-in from two triggers, which is the standard n8n
   evaluation pattern and requires no change to the agent's own config.
2. `Evaluation - Write Actual Answer`
   (`n8n-nodes-base.evaluation`, operation=`setOutputs`, same
   `dataTableId`), placed after `AI Agent - Currency Assistant`, mapping
   the agent's response into an `actual_answer` output column. This
   satisfies R1's step 2 ("write workflow outputs back to dataset").

Step 3 (quality score / `setMetrics`) is out of scope per TASK R3 —
`setOutputs` is independently functional without it.

### Export & docs (R4, R5)
- Re-export the updated live workflow to
  `workflows/ai-chat-currency-agent.json` (Export discipline).
- Extend the existing "## Evaluations" section in
  `docs/workflows/chat-agent/README.md` (added by task
  2026-08-10-workflow-evals-claude-only) with the dataset name/columns and
  what the two new nodes do — append to that section, do not duplicate
  the Claude-only judge-model note already there.

### Tooling (A4)
Data table creation/columns/rows via the n8n Data Table MCP tools; node
addition via the workflow update MCP tool. No manual credential step, no
literal secret values in any written artifact.

### Risk
Low-medium — two additive nodes plus one new Data Table; no change to
agent behavior, system prompt, or the tool-path branch. Main risk is the
fan-in wiring on `AI Agent - Currency Assistant` being done incorrectly;
Validator should confirm via `get_workflow_details` that both the
original chat path and the new evaluation path are intact.
