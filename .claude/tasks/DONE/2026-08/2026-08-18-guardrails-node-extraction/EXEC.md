# EXEC — 2026-08-18-guardrails-node-extraction

## v1

Implements PLAN.md v1 as written; no deviations.

### `workflows/ai-chat-currency-agent.json`
- Added `Guardrails - Screen User Input` (`@n8n/n8n-nodes-langchain.guardrails`
  v2, `operation: classify`), `text: ={{ $json.chatInput }}` (field name
  confirmed against `chat_agent_eval_dataset`'s `chatInput` column, which the
  docs already state mirrors the Chat Trigger's runtime field). `jailbreak`
  (threshold 0.7, default) and `topicalAlignment` (threshold 0.7, custom prompt
  scoping the assistant to currency conversion) enabled; no other guardrail
  category enabled.
- `AI Agent - Currency Assistant.parameters.options.systemMessage`: removed the
  "0. (Highest priority...)" paragraph in full. Rules 1-5 unchanged, no
  renumbering needed (confirmed no-op per PLAN.md). Node's `notes` updated to
  point at the new guardrail node instead of describing an in-prompt Rule 0.
  Repositioned to `[720, 300]` to make room for the inserted node on the canvas.
- Added `Set - Format Guardrail Refusal` (`n8n-nodes-base.set`), single `output`
  assignment with the fixed string `"Invalid request. I can only help with
  currency conversion."` — matches the `output`-field convention `Set - Format
  Agent Error` already established for terminal nodes that answer the chat.
- Connections: `Chat Trigger - Currency Agent Entry --main--> Guardrails -
  Screen User Input`; `Guardrails - Screen User Input` main output 0 (Pass) ->
  `AI Agent - Currency Assistant`, output 1 (Fail) -> `Set - Format Guardrail
  Refusal`; `OpenAI Chat Model - GPT`'s `ai_languageModel` output now fans out
  to both `AI Agent - Currency Assistant` and `Guardrails - Screen User Input`
  (one output, two targets in the same connection array — valid n8n fan-out).
  `Evaluation Trigger - Read Test Dataset -> AI Agent - Currency Assistant`
  left untouched, per PLAN.md's explicit bypass decision.
- Verified: `python3 -m json.tool` parses the file; manual connection-graph
  read-back confirms Pass/Fail wiring and the OpenAI fan-out are exactly as
  specified in PLAN.md (18 nodes total, up from 16). `validate_workflow` (n8n
  MCP) was not used — it validates Workflow-SDK TypeScript, not exported JSON,
  and this repo edits exported JSON directly per root CLAUDE.md's export
  discipline; no equivalent JSON-schema validation tool was available in this
  session.
- No literal secrets introduced. No new credentials required (Guardrails
  node reuses the existing OpenAI credential via the model fan-out).
- Note for Validator: the chat trigger's `responseMode` is `streaming`, which
  assumes the Agent is the node that streams the reply. Guardrails is inserted
  *before* the agent on the Pass path only (never between the agent and the
  response), so the existing streaming behavior on a passed message should be
  unaffected; this was not verified against a live n8n instance in this
  session (no running instance available) and should be re-checked against
  `.claude/tasks/DONE/.../ai-chat-currency-agent` precedent or a live smoke
  test before this ships.

### `docs/workflows/chat-agent/README.md`
- Top-level diagram: inserted `Guardrails - Screen User Input` between the
  trigger and the agent, with explicit (pass)/(fail) branch labels.
- New "## Guardrail" section (before "## Agent-level failure handling")
  describing the node, its two checks, its Pass/Fail routing, and the
  evaluation-path bypass.
- System prompt code block: removed Rule 0 text (rules renumber to nothing —
  1-5 already had their numbers).
- Explanatory paragraph below the prompt: replaced the Rule-0-specific
  sentences with a pointer to the new Guardrail section; left the Rule
  1/3/4 explanations unchanged since those rules didn't move.
- No task ids or stage references introduced (root CLAUDE.md docs/ rule).

## v2

Implements PLAN.md v2 (R6/A5) in both places: the exported file and the live
n8n Cloud instance (bLflLYfGzORWkjJV), since v1 had already been pushed and
published live per Engineer's follow-up request.

### `workflows/ai-chat-currency-agent.json`
- Added `OpenAI Chat Model - Guardrails` (`@n8n/n8n-nodes-langchain.lmChatOpenAi`,
  typeVersion 1.3), same `model`/`credentials` block as `OpenAI Chat Model -
  GPT` (`llmOpenAiApiCred`/"OpenAI"), positioned at `[480, 520]` below the
  Guardrails node.
- `Guardrails - Screen User Input`'s `notes` updated: no longer says "fan-out,
  no new credential"; now points at the dedicated model node and cites R6.
- Connections: removed `OpenAI Chat Model - GPT -> Guardrails - Screen User
  Input` (ai_languageModel); `OpenAI Chat Model - GPT` is back to its
  original single connection, to the agent only. Added `OpenAI Chat Model -
  Guardrails -> Guardrails - Screen User Input` (ai_languageModel).
- 19 nodes total (up from 18 in v1).

### `docs/workflows/chat-agent/README.md`
- Top diagram: added `OpenAI Chat Model - Guardrails` under the Guardrails
  branch.
- "## Guardrail" section: replaced the "reuses OpenAI Chat Model - GPT ... no
  separate credential needed" sentence with a description of the dedicated
  node (same credential, separate node instance).

### Live instance (bLflLYfGzORWkjJV, n8n Cloud)
- `update_workflow`: added `OpenAI Chat Model - Guardrails` node, removed the
  `OpenAI Chat Model - GPT -> Guardrails` connection, added `OpenAI Chat
  Model - Guardrails -> Guardrails` connection. 3 operations applied.
- Credential note: the new node could not reference `llmOpenAiApiCred` (that
  fixed id from `workflows/` doesn't exist as a credential on this specific
  cloud project -- `list_credentials` shows only one OpenAI credential,
  `n8n free OpenAI API credits`, a managed one). This mirrors the
  pre-existing gap already recorded in task 2026-08-08-ai-chat-currency-agent
  VALIDATION.md A2 (`OpenAI Chat Model - GPT` itself has no `credentials`
  block on the live instance either). Left the node without an explicit
  `credentials` parameter and let n8n's auto-assign fill it in --
  `autoAssignedCredentials` confirms it picked up "n8n free OpenAI API
  credits". This is a live-instance-only difference from the exported file
  (which references the portable `llmOpenAiApiCred` id per root CLAUDE.md's
  resource-locator convention); not a discrepancy this task can close, since
  provisioning a credential literally named "OpenAI" on this cloud project
  is outside this task's scope (same as the pre-existing gap).
- `publish_workflow` succeeded on retry (had failed once earlier while the
  Engineer had the editor open): `activeVersionId` now `2a3d7238-...`, so
  the published/active version -- not just the draft -- includes both the
  Guardrails node and its dedicated model node.
