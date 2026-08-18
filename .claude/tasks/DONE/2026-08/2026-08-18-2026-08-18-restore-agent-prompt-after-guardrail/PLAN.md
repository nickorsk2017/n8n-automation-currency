# PLAN — 2026-08-18-restore-agent-prompt-after-guardrail
owner: Planner
plan_version: 1

## Two entry points, one prompt field
The agent is fed by two triggers with different item shapes:

| Entry | Item reaching the agent | User message lives in |
|---|---|---|
| `Chat Trigger` -> `Guardrails` (Pass) | guardrail result | `guardrailsInput` |
| `Evaluation Trigger - Read Test Dataset` | dataset row | `chatInput` |

`promptType: "auto"` only ever reads `chatInput`, which is why the chat path
broke and the evaluation path did not.

## Design
Set `promptType: "define"` on `AI Agent - Currency Assistant` and give it:

```
text: ={{ $json.chatInput || $json.guardrailsInput }}
```

One expression covering both entries, ordered so the evaluation path (which
predates the guardrail) keeps the field it already uses, and the chat path falls
through to the guardrail's field.

## Rejected alternatives
- **A `Set` node on the Pass branch restoring `chatInput`.** Works, but adds a
  node whose only job is to rename a field, and leaves `promptType: "auto"`
  reading a value that is now synthesised rather than original — a second place
  to look when this next goes wrong. The expression states the dependency
  where the consumer is.
- **`$('Chat Trigger - Currency Agent Entry').item.json.chatInput`.** Reads the
  original message directly, which is appealing, but the node does not exist on
  the evaluation path and the expression would fail there — it trades one broken
  entry point for the other.
- **Routing the chat trigger to the agent in parallel with the guardrail.**
  Violates R3: the agent would receive the message regardless of the screening
  result.

## Risk
`$json.chatInput` is assumed to be the dataset column name on the evaluation
path, inferred from the fact that `promptType: "auto"` worked there before this
change. That inference is sound but untested here — the evaluation run is A2 and
belongs to the Engineer. If the column is named otherwise, the `||` fallback
means the chat path still works and only the evaluation path stays broken,
which is the same state as today rather than a regression.

## Verification
No actor can run either path: Cloud has no quota, Docker is unreachable.
Executor implements, states both A1 and A2 as unverified, and hands off. Given
this is the third defect to reach the Engineer through an unexercised path, the
Executor must not offer a structural argument as a substitute for the run.
