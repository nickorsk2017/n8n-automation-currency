# TASK — 2026-08-10-fix-eval-memory-session-id
owner: Engineer
immutable: true

## Requirements
- R1: Fix a bug in the live "AI Chat Currency Agent" workflow
  (`bLflLYfGzORWkjJV`), introduced by task
  2026-08-10-wire-eval-outputs-to-dataset: running the workflow from the
  Evaluation Trigger fails on `Memory - Chat Window` with
  "No session ID found" (confirmed via execution id 53,
  2026-08-11T01:02:35Z). `Memory - Chat Window` is configured
  `sessionIdType: fromInput`, `sessionKey: ={{ $json.sessionId }}` — the
  Chat Trigger supplies `sessionId`, but rows from
  `Evaluation Trigger - Read Test Dataset` (chat_agent_eval_dataset) do
  not have a `sessionId` field, only `chatInput`/`expected_answer`/row
  metadata, so the expression resolves to nothing and the node errors.
- R2: The fix must not change behavior for the normal chat path (Chat
  Trigger -> AI Agent), and must not touch the tool-path branch or the
  system prompt.
- R3: Re-export the updated live workflow to
  `workflows/ai-chat-currency-agent.json` (Export discipline).

## Acceptance
- A1: Running the workflow from `Evaluation Trigger - Read Test Dataset`
  (e.g. re-executing against execution 53's input row) succeeds through
  `Memory - Chat Window` and `AI Agent - Currency Assistant` without a
  "No session ID found" error.
- A2: A manual/chat-triggered execution still resolves a per-chat-session
  memory key exactly as before (no regression to follow-up-question
  behavior).
- A3: `workflows/ai-chat-currency-agent.json` matches the live workflow.
- A4: No literal credential/key values in any changed file.

## Constraints
- English only in all persisted files.
- Minimal, targeted fix — do not restructure the evaluation wiring added
  by task 2026-08-10-wire-eval-outputs-to-dataset beyond what's needed to
  fix the session ID issue.
