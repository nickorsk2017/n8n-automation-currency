# EXEC — 2026-08-17-stop-and-error-after-log-tool-error

## v1
Added `Stop And Error - Invalid Input` (`n8n-nodes-base.stopAndError`, v1) to
`workflows/ai-chat-currency-agent.json`, wired from `NoOp - Log Tool Error` ->
`Stop And Error - Invalid Input` via a new `main` connection.

- Params: `errorType: "errorMessage"`, `errorMessage: "={{ $json.message }}"`
  (reuses the message already produced by `Code - Validate Conversion Input`).
- Node type params confirmed against n8n's type definitions
  (`get_node_types` for `n8n-nodes-base.stopAndError`) before writing.
- Config validated with `validate_node_config` -> valid: true.
- Naming follows `<Kind> - <What>`; `notes` explains purpose and references
  this task (root CLAUDE.md n8n conventions).
- Behavior change flagged to and confirmed by Engineer before implementation:
  the invalid-input branch of the `convert_currency` tool sub-workflow now
  throws an n8n execution error instead of completing with a structured
  `success:false` JSON result. This means the AI Agent's system-prompt rule 3
  (graceful plain-language explanation of `success:false` results) no longer
  applies to this branch, since the tool call itself now fails. Out of scope
  for this task: reconciling the system prompt wording with the new failure
  mode (not requested; would require a Planner-routed change to
  `AI Agent - Currency Assistant`'s system message, a different node, per
  root CLAUDE.md "Reasoning belongs to the Planner").
- No other nodes/connections touched. No secrets introduced.
