# PLAN — 2026-08-18-chat-response-mode-lastnode
owner: Planner
plan_version: 1

## Why the widget sees nothing
`responseMode: "streaming"` is not a formatting preference — it changes which
transport carries the reply. The widget subscribes to a stream fed by an Agent
node with streaming enabled and ignores execution output entirely. This
workflow has no streaming producer on any path: the agent has no
`enableStreaming`, and all three chat-facing branches terminate in `Set` nodes,
which have no streaming capability. The widget therefore waits, receives zero
chunks, and reports `hasReceivedChunks: false`.

`lastNode` uses the opposite transport: the last executed node's item is the
reply, and it must carry `output`. The node type's own guidance is explicit
that a side-effect node must never be last on a chat path.

## Branch audit against the `lastNode` contract
Tracing every path a chat message can take:

| Path | Last node today | Emits `output`? |
|---|---|---|
| guardrail Fail | `Set - Format Guardrail Refusal` | yes — compliant |
| guardrail error (idx 2) | `Set - Format Guardrail Error` | yes — compliant |
| agent error | `Set - Format Agent Error` | yes — compliant |
| agent success | `Evaluation - Write Actual Answer` | **unknown — non-compliant by shape** |

Three of four are already correct, because the loggers were deliberately placed
mid-chain with a `Set` after them rather than at the end. That was not done for
this reason, but it happens to satisfy the contract exactly.

The fourth is the defect R3 names. `Evaluation - Write Actual Answer` is an
evaluation side-effect node that exists for the dataset-replay trigger, not for
chat, and it sits on the agent's success output so it runs for chat traffic too.
Whether it passes `output` through is undocumented and version-dependent.

## Design
1. `Chat Trigger - Currency Agent Entry`: set
   `options.responseMode: "lastNode"`.

2. New node `Set - Format Agent Reply` (`n8n-nodes-base.set` v3.5,
   `mode: manual`), connected after `Evaluation - Write Actual Answer`, with one
   assignment `output` (string) sourced explicitly from the agent rather than
   from whatever the evaluation node forwards:
   `={{ $('AI Agent - Currency Assistant').item.json.output }}`

   This makes all four chat-facing branches end in a `Set` node emitting
   `output` — one uniform contract, verifiable by reading the graph instead of
   by trusting a node's pass-through behaviour. It also leaves
   `Evaluation - Write Actual Answer` in place and functioning for the dataset
   trigger, which is its actual purpose.

   Rejected alternative: moving the evaluation node onto a parallel branch off
   the agent so the agent itself is last. Cleaner in principle, but it changes
   the evaluation wiring that three earlier tasks built and verified, for a
   benefit the Set node achieves without touching it. Not worth the blast
   radius in a task whose job is to fix the response transport.

3. Nothing else changes. No logger moves, no message text changes, no guardrail
   change.

## Risk the Executor must not paper over
`$('AI Agent - Currency Assistant').item.json.output` assumes the agent's
success item exposes `output` and that item pairing resolves through the
evaluation node. This is the same class of assumption that caused this task to
exist. It cannot be tested while the OpenAI quota is exhausted, because the
agent never runs. The Executor therefore:
- implements it,
- states in EXEC that the success path is **unverified**, naming this
  expression as the specific untested element,
- does not claim A1.

A2 is testable immediately and must be tested — in the widget, by the Engineer,
not through `get_execution`.

## Rollout
Cloud (`update_workflow` + `publish_workflow`) -> Engineer tests A2 in the Cloud
widget -> re-export `workflows/ai-chat-currency-agent.json` -> docs -> the
Docker stand picks it up through the already-open task
`2026-08-18-sync-chat-agent-to-docker`, which is where the Docker re-import
belongs rather than being duplicated here.

## Docs
`docs/workflows/chat-agent/README.md`: state the response mode, and state the
contract it imposes — every chat-terminal node emits `output`, side-effect nodes
sit mid-chain with a `Set` after them. That contract is currently satisfied by
accident of layout; writing it down is what stops the next change from breaking
it silently.
