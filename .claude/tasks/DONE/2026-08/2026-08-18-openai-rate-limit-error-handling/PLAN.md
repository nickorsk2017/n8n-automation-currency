# PLAN — 2026-08-18-openai-rate-limit-error-handling
owner: Planner

## v1

### Root cause / where the failure actually surfaces
`OpenAI Chat Model - GPT` is a LangChain sub-node connected via `ai_languageModel`
(not `main`), so it has no output branch of its own. When the OpenAI call fails
(rate limit, timeout, etc.), the error bubbles up through the node that calls
it: `AI Agent - Currency Assistant`. That node already has `retryOnFail: true`
(default 3 tries) at the n8n level, and `lmChatOpenAi` v1.3 additionally retries
internally (`options.maxRetries`, default 2) before surfacing anything -- so a
genuine failure reaching the user has already survived several retries and is
either sustained rate limiting or a hard error. Error handling therefore
belongs on `AI Agent - Currency Assistant`, not on the chat-model sub-node
(sub-nodes have no `onError`/second-output mechanism).

### Design
1. On node `AI Agent - Currency Assistant`: add generic node property
   `onError: "continueErrorOutput"` (keep existing `retryOnFail: true`
   unchanged). This gives the node a second `main` output (index 1) carrying
   the error item instead of failing the whole execution when all retries are
   exhausted.
2. New node `NoOp - Log Agent Error` (`n8n-nodes-base.noOp`, typeVersion 1),
   connected from `AI Agent - Currency Assistant` main output index 1. Passes
   the LangChain error item through unchanged so it is inspectable in the
   execution log (Executions view) -- same "log" mechanism already
   established in this workflow by `NoOp - Log Tool Error` for the tool
   branch; no new precedent introduced. `notes`: explains purpose, references
   TASK R1.
3. New node `Set - Format Agent Error` (`n8n-nodes-base.set`, latest
   typeVersion available), connected after `NoOp - Log Agent Error`. Produces
   a single string field named `output` (the same field name the agent's own
   successful runs use, per `Evaluation - Write Actual Answer` reading
   `$json.output`) via an expression along the lines of:
   `"Sorry, I couldn't reach the AI model just now" + ($json.error &&
   $json.error.message ? " (" + $json.error.message + ")" : "") + ". This is
   often temporary (e.g. rate limiting) -- please try your question again in
   a moment."`
   This is the terminal node of the error branch; its `output` field is what
   reaches the chat user. `notes`: explains purpose, references TASK R1.
   Executor: confirm exact expression syntax and current Set node
   typeVersion via `get_node_types` before writing -- do not guess the
   assignment schema.
4. No changes to `OpenAI Chat Model - GPT` parameters are required by this
   plan. If Executor's live verification (step 5) shows the specific failure
   is undiagnosable from `$json.error.message` alone, Executor may add
   `options.timeout`/`options.maxRetries` tuning on that node as a narrow,
   in-scope follow-up -- but must not change model/credentials.

### Open verification point (Executor must confirm empirically, Cloud first)
`Chat Trigger - Currency Agent Entry` uses `responseMode: streaming`. This
plan assumes that when `AI Agent - Currency Assistant` fails before emitting
any stream chunk and is rerouted via `continueErrorOutput`, the workflow
completes successfully through the new branch and n8n's chat widget falls
back to displaying the final node's `output` field (this is n8n's documented
behavior for a workflow that never opens a stream). Executor must force a
real failure on the Cloud instance (e.g. temporarily point the model at an
invalid model id, or exhaust the credential's quota) and confirm in the chat
UI that the friendly message appears, and in Executions that
`NoOp - Log Agent Error` shows the raw error -- before treating R1/A1 as
satisfied. If the friendly message does not reach the chat widget, this is
an `architecture` issue for re-routing back to Planner (e.g. switching
`responseMode` to `responseNodes` with an explicit `@n8n/n8n-nodes-langchain.chat`
response node), not something Executor should improvise around.

### Rollout order (R2/R3)
1. Apply the whole design (steps 1-3) to the live Cloud workflow
   (`bLflLYfGzORWkjJV`) via the n8n MCP (`update_workflow`), using
   `get_node_types`/`validate_node_config`/`validate_workflow` before and
   after the edit, per SDK reference.
2. Run the verification in the "Open verification point" section above on
   Cloud. Do not proceed to step 3 until it passes.
3. Fetch the final Cloud node graph (`get_workflow_details`) and hand-sync
   `workflows/ai-chat-currency-agent.json` to match it exactly (no literal
   credentials/keys -- credential references only, per root CLAUDE.md).
4. `make import FILE=ai-chat-currency-agent.json` to bring the local Docker
   instance to the same state, then `make drift ID=<docker_workflow_id>
   FILE=ai-chat-currency-agent.json` to confirm the file and the Docker
   instance match.
5. Repeat the same forced-failure verification against the Docker instance's
   chat trigger (A2).

### Docs
`docs/workflows/chat-agent/README.md` already documents the node graph as an
ASCII diagram and prose per-node explanation (see "Two entry points in one
file" section). Add the two new nodes to that diagram as a labeled error
branch off `AI Agent - Currency Assistant`, and a short paragraph describing
the behavior (a sustained OpenAI failure, e.g. rate limiting, now returns a
plain-language chat message instead of a silent/opaque failure, and is
visible in Executions via `NoOp - Log Agent Error`). No task ids or
requirement ids in the docs prose, per the `docs/` rules in root CLAUDE.md.

### Files/resources touched
- Live Cloud workflow `bLflLYfGzORWkjJV` (via n8n MCP)
- Live Docker n8n instance (via `make import`)
- `workflows/ai-chat-currency-agent.json`
- `docs/workflows/chat-agent/README.md`
