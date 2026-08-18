# TASK — 2026-08-18-2026-08-18-guardrail-error-logging-and-static-agent-error
owner: Engineer
immutable: true

## Context
Observed in the live chat: the message `100 USD -> EURO` returned the raw n8n
error text `It looks like you've used all your free n8n AI credits. Follow our
<a href="...">documentation</a> to create your own OpenAI credential.` directly
in the chat window, HTML markup included. The `error_log` Data Table stayed
empty (`Total 0`).

The cause is that `Guardrails - Screen User Input` has no `onError` setting and
no error branch. It is the first node after `Chat Trigger - Currency Agent
Entry`, so when its classifier sub-node `OpenAI Chat Model - Guardrails` fails,
the failure aborts the execution before `AI Agent - Currency Assistant` is ever
reached — and therefore before any of the existing error handling
(`Execute Workflow - Log Agent Error`, `Set - Format Agent Error`) can run. The
agent branch is already handled; the guardrail branch is not, and it sits
upstream of everything else.

## Requirements
- R1: A failure of `Guardrails - Screen User Input` (including a failure of its
  `OpenAI Chat Model - Guardrails` sub-node) must write a row to the `error_log`
  Data Table via the shared `Error Logger` sub-workflow
  (`w5dvcvpZ5b9AVTLC`, `workflows/error-logger.json`), the same mechanism the
  agent and tool branches already use.
- R2: The same failure must return a message to the chat user through the
  workflow's normal `output` field, so the execution completes rather than
  aborting. No raw n8n or OpenAI error text, and no HTML markup, may reach the
  chat user on this path.
  **Amended 2026-08-18 by the Engineer, after EXEC v1 established that the
  guardrail node reports a failed classifier on its Fail output rather than
  throwing:** distinguishing "the guardrail rejected the input" from "the
  guardrail could not run" is explicitly out of scope. The binding requirement
  is that the failure is recorded in `error_log`; which of the two fixed
  messages the user receives is not. Reaching the user with the existing
  refusal text on a classifier failure is acceptable.
- R3: `Set - Format Agent Error` must emit a fixed static English string with no
  expression interpolation of the underlying error. Proposed text:
  `"An error occurred - please try again. (The error has been logged for the
  system administrator and will be fixed shortly.)"`
  The raw error must still be recorded in `error_log`, so removing it from the
  user-facing string loses nothing diagnostically.
- R4: Cloud first. Implement and verify on the live Cloud workflow
  `bLflLYfGzORWkjJV` via the n8n MCP, then re-export to
  `workflows/ai-chat-currency-agent.json`.
- R5: No secrets in the exported JSON.
- R6: New/changed nodes follow the repo's n8n conventions: `<Kind> - <What>`
  naming, and a `notes` value explaining the node's purpose and citing this
  task's requirement id.
- R7: `docs/workflows/chat-agent/README.md` describes the resulting behavior.
  Its existing sentence saying `Set - Format Agent Error` produces a message
  with "no technical detail" is currently false against the implementation;
  after this task the documentation and the node must agree.

## Acceptance
- A1: Forcing a `Guardrails - Screen User Input` failure on the Cloud instance
  (e.g. by pointing `OpenAI Chat Model - Guardrails` at an invalid credential or
  model id) produces exactly one new row in `error_log` naming the guardrail
  node as its context, and the execution ends with status success.
- A2: On that same failure the chat user receives one of the workflow's fixed
  messages, never the n8n credits/HTML text seen in the observed incident. Per
  the R2 amendment, either the R3 message or the existing guardrail refusal
  text satisfies this.
- A3: `Set - Format Agent Error` contains no reference to `$json.error` in its
  assigned value.
- A4: `workflows/ai-chat-currency-agent.json` matches the published Cloud graph.
- A5: No API keys or other secrets appear anywhere in the exported JSON.
- A6: `docs/workflows/chat-agent/README.md` is accurate against the final node
  graph, including the guardrail failure path.

## Constraints
- Do not weaken or disable the guardrail itself. A classifier failure must not
  become an implicit pass that lets unscreened input reach the agent — the
  failure path is an error path, not a fallback into the agent.
- Reuse the existing shared `Error Logger` sub-workflow; do not introduce a
  second logging mechanism.
- The Docker instance sync is deliberately out of scope here: it is already
  tracked as issue V-1 on task 2026-08-18-openai-rate-limit-error-handling and
  belongs to that task's closure, not this one.
