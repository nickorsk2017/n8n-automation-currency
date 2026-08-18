# EXEC — 2026-08-10-fix-eval-memory-session-id
# EXEC — 2026-08-10-fix-eval-memory-session-id

## v1 (LOW — no PLAN.md; implements TASK directly)

Root cause (confirmed via execution 53): `Memory - Chat Window` had
`sessionIdType: "fromInput"`, which hardcodes reading a field literally
named `sessionId` from the input — it does not use the `sessionKey`
expression at all in that mode (n8n rejects `sessionKey` as invalid when
`sessionIdType != "customKey"`). Dataset rows from
`Evaluation Trigger - Read Test Dataset` have no `sessionId` field, only
`chatInput`/`expected_answer`/row metadata, so the node errored with "No
session ID found".

Fix: switched the node to `sessionIdType: "customKey"` with
`sessionKey = {{ $json.sessionId || 'eval-row-' + $json.row_id }}` —
uses the Chat Trigger's real `sessionId` when present (unchanged chat
behavior, R2/A2) and falls back to a per-row deterministic key for
evaluation runs (fixes R1/A1). Published live.

Verified via `test_workflow` (execution 54, pinned
`Evaluation Trigger - Read Test Dataset` to the exact row that failed in
execution 53): `Memory - Chat Window` and `AI Agent - Currency Assistant`
both succeeded, `Evaluation - Write Actual Answer` wrote the answer.
Verified via `execute_workflow` chat input (execution 56, "Convert 20 USD
to GBP"): normal chat path unaffected, real `sessionId` used, tool called,
correct conversion returned.

Re-exported `workflows/ai-chat-currency-agent.json`: updated
`Memory - Chat Window` parameters to match the live node, updated its
`notes`. No other nodes/connections changed. No literal credential/key
values in the file (grep clean).
