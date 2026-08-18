# EXEC — 2026-08-18-chat-response-mode-lastnode
owner: Executor
exec_version: 1

## Applied to Cloud `bLflLYfGzORWkjJV`, published `4cb978d5`
- `Chat Trigger - Currency Agent Entry`:
  `options.responseMode` `"streaming"` -> `"lastNode"`.
- Added `Set - Format Agent Reply` (`n8n-nodes-base.set` v3.5) after
  `Evaluation - Write Actual Answer`, one `output` assignment sourced from
  `$('AI Agent - Currency Assistant').item.json.output`.
- No other change. Loggers, message texts, guardrail config and the evaluation
  wiring are untouched.

## Structural verification (what could be verified without the widget)
Traced every node reachable from the chat trigger and listed those with no
`main` successor — i.e. every node that can be the last one on a chat run:

```
Set - Format Agent Reply        n8n-nodes-base.set   emits output = True
Set - Format Agent Error        n8n-nodes-base.set   emits output = True
Set - Format Guardrail Refusal  n8n-nodes-base.set   emits output = True
Set - Format Guardrail Error    n8n-nodes-base.set   emits output = True
responseMode = lastNode
```

Four of four comply with the contract. This is a property of the graph, so it
holds for every input rather than for a sampled one — but it establishes only
that the *shape* is right. It says nothing about whether the widget renders the
reply, which is the actual acceptance criterion.

## NOT VERIFIED — deliberately, per the TASK constraint
Neither A1 nor A2 is claimed. The TASK forbids substituting
`execute_workflow` / `get_execution` for a widget test, since doing exactly that
is what let this defect ship twice. No execution was run for verification
purposes.

Two separate untested elements, which should not be conflated:
- **A2 (guardrail path)** is testable right now — the guardrail fails closed on
  every message while the quota is exhausted. Only the Engineer can test it,
  in the widget.
- **A1 (success path)** is untestable until a working OpenAI credential exists,
  because the agent never runs. The specific unproven element is
  `$('AI Agent - Currency Assistant').item.json.output` — whether the agent's
  success item exposes `output` under that name and whether item pairing
  resolves through `Evaluation - Write Actual Answer`. PLAN v1 named this as the
  same class of assumption that caused this task; it is recorded here rather
  than quietly assumed.

## Repository and docs
- `workflows/ai-chat-currency-agent.json` re-exported from the published graph
  (23 nodes). Re-verified: zero residual node-field differences against Cloud
  excluding `credentials`, `connections` identical, secret scan clean. The two
  credential blocks are preserved per the deviation documented on task
  2026-08-18-guardrail-error-logging-and-static-agent-error.
- `docs/workflows/chat-agent/README.md`: new section "How a reply reaches the
  chat widget" stating the response mode, the terminal-node contract it imposes,
  why `Set - Format Agent Reply` exists, and that execution data is not evidence
  the chat works.

## Handoff
Engineer tests A2 in the Cloud chat widget and reports the result. A1 waits on a
working OpenAI credential. Docker re-import is not duplicated here; it belongs
to the open task `2026-08-18-sync-chat-agent-to-docker`, which should be run
against this corrected file rather than the previous one.
