# TASK — 2026-08-18-restore-agent-prompt-after-guardrail
owner: Engineer

## Context
Root cause of the agent failure, recovered from the first `error_log` row that
carried a serialised item (Docker row 5, execution 9):

```
AI Agent failed; raw item: {"guardrailsInput":"100 USD →EURO","checks":[
  {"name":"jailbreak","triggered":false,...},
  {"name":"topicalAlignment","triggered":false,...}],
 "error":"No prompt specified"}
```

`Guardrails - Screen User Input` replaces the incoming item with its own result
object — `{guardrailsInput, checks}` — rather than passing the trigger's item
through. `AI Agent - Currency Assistant` uses `promptType: "auto"`, which reads
the user message from `chatInput`. That field no longer exists on the Pass
branch, so the agent raises `No prompt specified` on every chat message.

The chat path has been broken since the guardrail node was introduced
(2026-08-18-guardrails-node-extraction). It went unnoticed because the Pass
branch was never once executed: on Cloud the classifier failed on exhausted AI
credits every time, so traffic always took the Fail branch. The first instance
with a working OpenAI key — the Docker stand — surfaced it immediately.

## Requirements
- R1: `AI Agent - Currency Assistant` must receive the user's message on the
  chat path, where the incoming item carries `guardrailsInput`.
- R2: The evaluation path must keep working. `Evaluation Trigger - Read Test
  Dataset` feeds the agent directly, without passing through the guardrail, so
  its items do not have `guardrailsInput`. Whatever R1 does must not assume a
  guardrail ran.
- R3: Do not weaken or bypass the guardrail, and do not restore the raw
  `chatInput` by routing around it. The screening must still happen before the
  agent sees anything.
- R4: Cloud first, then re-export to
  `workflows/ai-chat-currency-agent.json`, then Docker via the open sync task.

## Acceptance
- A1: A conversion question typed into the chat widget on the Docker stand
  returns a converted amount.
- A2: The evaluation dataset run still produces answers.
- A3: `workflows/ai-chat-currency-agent.json` matches the published Cloud graph.

## Constraints
- Verification is the Engineer's, on Docker, in the widget. Cloud has no quota;
  an actor claiming A1 from execution data repeats the error that hid both this
  defect and the response-mode one.
- This is the third defect in a row that survived validation because the happy
  path was never executed. Any actor tempted to accept a structural argument in
  place of a run should treat that impulse as the warning it is.
