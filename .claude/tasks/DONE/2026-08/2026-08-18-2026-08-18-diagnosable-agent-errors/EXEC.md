# EXEC — 2026-08-18-diagnosable-agent-errors
owner: Executor
exec_version: 1

## Hypothesis withdrawn before implementing
TASK named `builtInTools` a "live suspect" for the agent failure. The Engineer's
execution-7 screenshot refutes that: `OpenAI Chat Model - Guardrails` completed
two successful calls in the same run, and it carries the identical
`builtInTools: {}`. A field present on both a working and a failing node does
not distinguish them. R3 is therefore implemented as what it always was on its
own terms — removal of an empty field that validation rejects — and not as a
fix for the agent. Recorded so no one later reads the removal as the cure.

## Applied to Cloud `bLflLYfGzORWkjJV`, published `bfcae51b`
- `Execute Workflow - Log Agent Error` and
  `Execute Workflow - Log Guardrail Error`: `message` expression now joins
  `error.message` and `error.description` when either exists, and otherwise
  serialises the item — `JSON.stringify($json).slice(0, 500)` — instead of
  emitting a fallback string that discards it. `[execution <id>]` stays outside
  the conditional, so it is present on every row including the serialised case.
- `OpenAI Chat Model - GPT` and `OpenAI Chat Model - Guardrails`:
  `builtInTools` removed via `updateNodeParameters` with `replace: true`
  (`setNodeParameter` cannot delete a key). `model` and `options` passed through
  unchanged; `responsesApiEnabled` deliberately not introduced, per R4.

## A1 — MET, directly evidenced
`update_workflow` returned `"validationWarnings": []`. The two
`builtInTools` warnings that accompanied every previous call on this workflow
are gone.

## A2 — NOT verified, and cannot be by any actor
Requires an agent failure to occur and be read afterwards. Cloud has no OpenAI
quota so the agent never runs; Docker is unreachable from this environment. Per
the TASK constraint the Engineer verifies this on the Docker stand. No execution
was run as a substitute.

What A2 will look like when it is checked: the next `AI Agent - Currency
Assistant` failure should produce a row reading
`AI Agent failed; raw item: {...} [execution N]` rather than
`AI Agent failed (no error message available) [execution N]`. The serialised
item is what identifies the real cause, which remains unknown.

## Repository
`workflows/ai-chat-currency-agent.json` re-exported from the published graph.
Re-verified: zero residual node-field differences against Cloud excluding
`credentials`, `connections` identical, no `builtInTools` key on any node,
secret scan clean.

## Docs
Not touched. PLAN v1 anticipated this: the change is internal to two logger
expressions and to a model node's parameter set. `docs/workflows/chat-agent/`
documents the terminal-node contract and the logging convention, neither of
which changed. Adding prose about an expression's fallback branch would be the
kind of documentation that goes stale without being read.

## Handoff
Engineer re-imports to Docker (`make import-all`) and sends one chat message.
Two outcomes, both useful:
- the agent fails again -> the row now carries the serialised item, which is the
  first real evidence about the cause;
- the agent succeeds -> A1 of task 2026-08-18-chat-response-mode-lastnode
  becomes testable for the first time, since `Set - Format Agent Reply` and its
  `$('AI Agent - Currency Assistant').item.json.output` expression have never
  run.
