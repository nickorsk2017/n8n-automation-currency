# TASK — 2026-08-18-diagnosable-agent-errors
owner: Engineer

## Context
The Docker stand produced four `error_log` rows. Three of them read
`AI Agent failed (no error message available)` — the fallback branch of
`Execute Workflow - Log Agent Error`'s expression. `$json.error.message` is
absent or empty on the agent's error output, so the assumed item shape is wrong
and the logger records nothing usable about a failure that is currently
blocking the whole chat path.

This also settles observation N1 from task
2026-08-18-guardrail-error-logging-and-static-agent-error, negatively: the
`$json.error.description` clause added there cannot help, since not even
`.message` is present.

Separately, `builtInTools: {}` on both OpenAI model nodes raises
`This field is only allowed when: /responsesApiEnabled=true` on every
`update_workflow` call. It has been dismissed three times as harmless on the
grounds that Cloud tolerates it. That reasoning is weak: on Cloud the agent
never actually reached the provider, because the guardrail failed first on
exhausted credits. On Docker the classifier succeeds and the agent does make a
real call — and fails. The field is now a live suspect, not a cosmetic warning.

## Requirements
- R1: When the agent's error branch runs, the `error_log` row must contain
  enough to diagnose the failure, whatever the error item's shape. A fallback
  that discards the item is not acceptable — if no known field is present, the
  raw item must be serialised into the message.
- R2: The same treatment for `Execute Workflow - Log Guardrail Error`, which
  makes the identical assumption about `$json.error.message`.
- R3: Remove `builtInTools` from `OpenAI Chat Model - GPT` and
  `OpenAI Chat Model - Guardrails`. The field is empty, is rejected by
  validation, and is a candidate cause of the agent failure. Removal is correct
  on its own terms regardless of whether it turns out to be the cause.
- R4: Do not change model, credentials, or `responsesApiEnabled`. R3 is a
  removal, not a migration to the Responses API.
- R5: Cloud first, then re-export to `workflows/ai-chat-currency-agent.json`,
  then Docker via the open sync task.

## Acceptance
- A1: A `update_workflow` call against the workflow reports no validation
  warnings.
- A2: The next agent failure writes an `error_log` row whose `message` is not
  the bare fallback — it names a field value or carries the serialised item,
  plus the `[execution N]` pointer.
- A3: `workflows/ai-chat-currency-agent.json` matches the published Cloud graph.

## Constraints
- The agent path cannot be exercised from any actor's environment: Cloud has no
  OpenAI quota, and Docker is unreachable. A2 is therefore verified by the
  Engineer on the Docker stand, not claimed by an actor.
- Whether R3 fixes the agent failure is an open question this task does not
  answer. It removes an invalid field and a confound; if the agent still fails
  afterwards, the improved logging from R1 is what identifies the real cause.
