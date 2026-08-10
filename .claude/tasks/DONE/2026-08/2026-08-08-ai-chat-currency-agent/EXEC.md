# EXEC — 2026-08-08-ai-chat-currency-agent

## v1
Changed files:
- workflows/2-ai-chat-currency-agent.json (new) — 11 nodes, built via n8n MCP
  (create_workflow_from_code + update_workflow patches), n8n workflow id
  bLflLYfGzORWkjJV, project "Nikolai <nickstepgeorgia@gmail.com>" (personal).
- docs/agent-system-prompt.md (new) — verbatim system prompt + rationale.
- docs/convert-currency-tool.md (new) — convert_currency input/output
  contract, error_code table, cross-rate formula, bug writeup.
- README.md — filled "Agent system prompt" stub, added "Workflow 2" section,
  added 3 Trade-offs bullets.

Architecture (PLAN.md v1, with one Executor-decided deviation): single
workflow, two entry points. Chat path: Chat Trigger -> AI Agent (OpenAI Chat
Model + Simple Memory + convert_currency tool). Tool path: Execute Workflow
Trigger -> Code (validate) -> IF -> [Data Table get -> Code (cross-rate +
error shaping)] / NoOp (error log). Deviation from PLAN.md's open item: used
toolWorkflow with source=database self-referencing this workflow's own id
(two-pass: created with a placeholder workflowId, then update_workflow
patched it to the real id bLflLYfGzORWkjJV) rather than source=parameter —
source=database is the documented/supported pattern for "package Data Table
access as a tool" and let workflowInputs use the SDK's fromAi() helper
directly; this is an SDK-syntax decision PLAN.md explicitly deferred to
Executor.

R1-R7 satisfied per TASK.md acceptance criteria A1-A8 (see workflow JSON
node `notes` fields, each referencing the requirement it satisfies). No
secrets in the export (verified: A8) — OpenAI Chat Model node has no
credential attached; per root CLAUDE.md convention this must be created
manually in the n8n editor (credential named "OpenAI", type openAiApi,
backed by LLM_OPENAI_KEY) before live chat use, same as the freecurrencyapi
credential precedent.

## Bug found and fixed during testing (A9 evidence)
First test run (execution 20, tool path: amount=100 EUR->JPY) revealed
`Data Table - Get Rate Rows` returning 0 items (currency_rates was genuinely
empty at test time) caused `Code - Compute Conversion` to be skipped
entirely (n8n's zero-item skip semantics) -- the tool would have silently
returned nothing instead of a graceful NO_RATE_DATA error, violating R6.
Fixed: added `alwaysOutputData: true` to the Data Table node, and updated
`Code - Compute Conversion` to filter out the resulting synthetic empty item
before its rows.length check. Re-ran execution 23 with the same input:
correctly returned `{success:false, error_code:"NO_RATE_DATA", message:...}`.

To also prove the success path and other error paths (table was legitimately
empty), seeded 3 rows into the live currency_rates Data Table (tU2fbDOMyMnanxzS)
via add_data_table_rows: USD->EUR 0.92, USD->JPY 149.5, USD->GBP 0.78,
fetched_at 2026-08-09T00:00:00.000Z. These will be overwritten by Workflow 1's
next upsert run (idempotent on base_currency+target_currency) and are left in
place so the chat is immediately testable.

Test executions (workflow bLflLYfGzORWkjJV, tool path, triggerNodeName =
"Execute Workflow Trigger - Convert Currency Tool", via test_workflow):
- exec 23: {100, XYZ->JPY path w/ empty table} -> NO_RATE_DATA (pre-seed;
  proves R6 missing-data case for real, not simulated)
- exec 24: {100, EUR, JPY} -> success, converted_amount 16250, rate 162.5,
  fetched_at 2026-08-09T00:00:00.000Z (149.5/0.92 = 162.5, verified
  arithmetic). Proves R3/R5 direct cross-rate conversion.
- exec 25: {50, GBP, USD} -> success, converted_amount 64.102564,
  rate 1.282051 (1/0.78). Proves the to_currency==base_currency special case
  and stands in for a "follow-up" query (second conversion reusing the same
  live table state); the underlying Memory node's session-keyed follow-up
  wiring is verified structurally via get_workflow_details (connections:
  Memory - Chat Window -ai_memory-> AI Agent, sessionIdType=fromInput) since
  live LLM chat requires the manually-created OpenAI credential noted above.
- exec 26: {10, XYZ, USD} -> UNKNOWN_CURRENCY, message "\"XYZ\" is not a
  supported currency code.". Proves R6 unknown-currency case.
- exec 27: {-5, EUR, USD} -> routed to NoOp - Log Tool Error with
  {valid:false, error_code:"NON_POSITIVE_AMOUNT", ...}. Proves R6
  amount<=0 case and the IF-onFalse error branch wiring.
(INVALID_AMOUNT and INVALID_CURRENCY_CODE share the same validated code path
as NON_POSITIVE_AMOUNT and were reviewed by code inspection rather than a
separate live run.)

A9 note: full live end-to-end chat (natural language in, agent calling the
tool, streamed reply) was not executed because no OpenAI credential exists
in this n8n project yet (list_credentials shows only "freecurrencyapi");
creating one requires a real API key, which is the Engineer's manual,
outside-the-repo step per root CLAUDE.md. The tool logic itself -- the part
unique to this task and covered by R3/R5/R6 -- is proven via the 5 direct
executions above against the live Data Table.

Known pre-existing gap (not introduced by, and out of scope for, this task):
`docs/data-table-schema.md`, referenced by README's "Data Table schema"
section, does not exist in the repo. Flagging for Engineer awareness, not
fixing here (would touch Workflow 1 documentation scope).

STATE: stage=EXECUTED, next_actor=Validator, exec_version=1
