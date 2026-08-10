# EXEC — 2026-08-09-attach-openai-credential-wf2

## v1
Changed files:
- workflows/2-ai-chat-currency-agent.json — added credentials.openAiApi
  (id kpxxTKpEgoMAKTNT, name "n8n free OpenAI API credits") to "OpenAI Chat
  Model - GPT"; added an explicit `schema` array to the convert_currency
  tool's `workflowInputs` (ResourceMapperValue).

Two real bugs found and fixed via live E2E testing (workflow bLflLYfGzORWkjJV):

1. Self-referencing toolWorkflow call failed with "Workflow is not active
   and cannot be executed." (execution 28) -- n8n requires the target
   workflow of a source=database toolWorkflow call to be active, even when
   it's calling itself. Fixed by publishing/activating the workflow
   (publish_workflow).
2. After activating, the tool call succeeded but the Execute Workflow
   Trigger received {amount:null, from_currency:null, to_currency:null}
   (execution 29 -> sub-execution 30) despite the $fromAI() expressions
   being correctly set and the Agent correctly extracting {100, EUR, JPY}
   -- the ResourceMapperValue mapping silently failed to bind without an
   explicit `schema` describing the 3 target fields. Fixed by adding the
   schema array; the agent then correctly explained the resulting
   INVALID_AMOUNT error in plain language to the user in the meantime,
   which is itself further live evidence of R6's error-translation working
   correctly even when the underlying cause was a workflow bug, not user
   input.

Live E2E evidence after both fixes, republished (activeVersionId
4a6cf640-0ab1-461d-9abb-37c861b38714):
- execution 31: chatInput "How much is 100 EUR in JPY?" -> Agent called
  convert_currency with {amount:100, from_currency:"EUR", to_currency:"JPY"}
  (sub-execution 32) -> tool returned {success:true, converted_amount:16250,
  rate:162.5, fetched_at:"2026-08-09T00:00:00.000Z"} -> Agent replied "100
  EUR is 16,250 JPY (rate: 1 EUR = 162.5 JPY, last updated 2026-08-09)."
  Full A2/A3/A4/A9 live proof.
- execution 33: chatInput "and in GBP?" (fresh session -- execute_workflow's
  MCP interface does not expose a session-id parameter, so true multi-turn
  memory could not be driven from this tool; the Memory node's wiring was
  already verified structurally in the prior task) -> Agent correctly asked
  a clarifying question per system-prompt Rule 4 rather than guessing,
  proving the ambiguous-request-handling requirement live.
- execution 28/29 (pre-fix): tool errors surfaced were still translated to
  plain, non-technical language by the agent in both cases ("couldn't reach
  the exchange-rate service", "the amount you gave... looks invalid"),
  additional live evidence for R6.

STATE: stage=EXECUTED, next_actor=Validator, exec_version=1
