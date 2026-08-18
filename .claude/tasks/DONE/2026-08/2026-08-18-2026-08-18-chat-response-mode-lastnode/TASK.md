# TASK — 2026-08-18-chat-response-mode-lastnode
owner: Engineer

## Context
The chat widget returns nothing. On the Docker stand a real message produced:

```
[No response received. This could happen if streaming is enabled in the
 trigger but disabled in agent node(s)]
```

`Chat Trigger - Currency Agent Entry` is set to `options.responseMode:
"streaming"`, which makes the widget wait for stream chunks from an Agent node
with streaming enabled. The agent has no `enableStreaming`, and every terminal
branch ends in a `Set` node, which cannot stream at all. So nothing ever
reaches the widget.

This is **not** Docker-specific — the same configuration is live on Cloud. It
went unnoticed because tasks 2026-08-18-openai-rate-limit-error-handling and
2026-08-18-guardrail-error-logging-and-static-agent-error both verified the
user-facing message through `execute_workflow` / `get_execution`, which reads
execution data. The widget does not read execution data. Both tasks' acceptance
of "the user sees the message" was measured against the wrong consumer and is
retroactively unsound, though everything they asserted about `error_log` and
about the stored node values remains correct.

The Engineer has chosen the non-streaming direction.

## Requirements
- R1: `Chat Trigger - Currency Agent Entry` uses `options.responseMode:
  "lastNode"`.
- R2: Every branch that can terminate a chat run must end in a node emitting
  `{ output: "<reply text>" }`. Per the chat trigger's own guidance, a
  side-effect node (Data Table insert, Execute Workflow, HTTP Request) must
  never be the last node on a chat path.
- R3: The successful-conversion path currently ends at
  `Evaluation - Write Actual Answer`, an evaluation side-effect node fed from
  the agent's success output. It must not be what the widget reads. Whatever
  the fix, the reply on a successful conversion must be the agent's answer.
- R4: Cloud first, then re-export to
  `workflows/ai-chat-currency-agent.json`, then the Docker stand.
- R5: No secrets in the exported JSON; node conventions per root CLAUDE.md.
- R6: `docs/workflows/chat-agent/README.md` reflects the response mode and the
  terminal-node contract.

## Acceptance
- A1: A successful conversion typed into the **chat widget** returns the
  agent's answer.
- A2: A guardrail outcome typed into the **chat widget** returns the fixed
  refusal text, and still writes one `error_log` row.
- A3: `workflows/ai-chat-currency-agent.json` matches the published Cloud graph.
- A4: Docs updated.

## Constraints
- **Verification must be done in the chat widget, by the Engineer.** No actor
  may accept `execute_workflow` / `get_execution` output as evidence for A1 or
  A2 — that is the precise mistake this task exists to correct. An actor that
  cannot open the widget reports the change as unverified and halts.
- The OpenAI quota is exhausted, so A1 cannot be tested until a working
  credential exists. A2 can be tested immediately, since the guardrail fails
  closed on every message.
