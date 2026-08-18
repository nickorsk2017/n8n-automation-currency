# PLAN — 2026-08-18-guardrails-node-extraction

## v1

### Node choice
Use `@n8n/n8n-nodes-langchain.guardrails` (v2), `operation: classify`. It is the
built-in node for this purpose (root CLAUDE.md: prefer built-ins over Code/prompt
logic), has a `jailbreak` check (covers the prompt-injection half of Rule 0) and a
`topicalAlignment` check (covers the off-topic half of Rule 0, via a custom prompt
describing the currency-conversion business scope). `classify` gives two outputs:
0 = Pass, 1 = Fail — exactly the Pass-through-to-agent / Fail-with-fixed-message
branch Rule 0 currently implements in prompt form.

`classify`'s `jailbreak`/`topicalAlignment` checks require a connected `model`
subnode (`ai_languageModel`). Reuse `OpenAI Chat Model - GPT` for this — n8n
permits one sub-node's output to fan out to multiple parents, so no new
credential/model node is needed.

### Wiring
Insert the new node on the main chat path, between the trigger and the agent:

```
Chat Trigger - Currency Agent Entry
  --main--> Guardrails - Screen User Input
              --output 0 (Pass)--> AI Agent - Currency Assistant
              --output 1 (Fail)--> Set - Format Guardrail Refusal
```

`OpenAI Chat Model - GPT` gains a second `ai_languageModel` connection, to
`Guardrails - Screen User Input`, in addition to its existing one to the agent.

`Evaluation Trigger - Read Test Dataset -> AI Agent - Currency Assistant` is left
unchanged (bypasses the guardrail). Rationale: that edge feeds a fixed evaluation
dataset of known-valid conversion questions, not live user input; routing it
through the guardrail would make evaluation runs depend on an extra LLM call and
risk false positives against a dataset it should return by construction. This
mirrors the existing design where the evaluation path and the chat path are
already separate entry points into the same agent.

### New nodes

**`Guardrails - Screen User Input`** (`@n8n/n8n-nodes-langchain.guardrails`,
`operation: classify`)
- `text`: expression pulling the trigger's chat input field (Executor confirms the
  exact field name, expected `{{ $json.chatInput }}`, via `get_node_types` on
  `@n8n/n8n-nodes-langchain.chatTrigger` before wiring).
- `guardrails.jailbreak`: enabled, default threshold (0.7) — detects
  prompt-injection / instruction-override attempts (was Rule 0, first clause).
- `guardrails.topicalAlignment`: enabled, default threshold (0.7), with a custom
  prompt stating the assistant's scope is currency conversion only and any other
  request (weather, general knowledge, code execution, etc.) is out of scope (was
  Rule 0, second clause).
- No other guardrail checks (`keywords`, `nsfw`, `pii`, `secretKeys`, `urls`,
  `custom`, `customRegex`) are enabled — out of scope for this task, which
  replaces Rule 0 only, not a general content-safety pass.
- `notes`: explains it replaces the in-prompt Rule 0 guardrail, cites this task id
  and its Pass/Fail outputs.

**`Set - Format Guardrail Refusal`** (`n8n-nodes-base.set`)
- One assignment, `output` (string, fixed value) =
  `"Invalid request. I can only help with currency conversion."`
- Field name `output` matches the existing convention (`Set - Format Agent Error`)
  for the terminal node whose `output` becomes the chat reply on `responseMode:
  lastNode`/`streaming`.
- `notes`: explains this is the Fail-branch terminal node for the guardrail,
  returning the exact fixed English refusal without echoing user input or the
  system prompt, and without any tool/agent call downstream — satisfies R3.

### System prompt change
In `AI Agent - Currency Assistant.parameters.options.systemMessage`: delete the
"0. (Highest priority...)" paragraph in full. Rules 1-5 keep their existing
numbers unchanged (they were already numbered independently of Rule 0) — no
renumbering needed, R2's "renumber as needed" clause turns out to be a no-op here,
recorded so the Validator doesn't flag it as skipped.

Update the node's `notes` field: remove the sentence describing Rule 0 as an
in-prompt guardrail; add a sentence pointing to `Guardrails - Screen User Input`
as where that behavior now lives, referencing this task id.

### Docs change
`docs/workflows/chat-agent/README.md`: wherever it currently describes the
prompt-injection/off-topic refusal as part of the system prompt (Rule 0), update
it to describe the dedicated `Guardrails - Screen User Input` node instead
(jailbreak + topicalAlignment checks, Pass/Fail branching, fixed refusal text),
and correct the system-prompt excerpt/description to match the trimmed prompt.
No task ids or stage references are added, per root CLAUDE.md's `docs/` rules.

### Out of scope
- Any other guardrail category (NSFW, PII, secrets, URLs) — not requested, not a
  regression of current behavior since none existed before.
- Changing `convert_currency` tool contract, Rules 1-5 content/order, or the
  evaluation dataset.

## v2

Addresses R6/A5 (Engineer, after reviewing the deployed v1 change): give
`Guardrails - Screen User Input` its own dedicated OpenAI Chat Model node
instead of fanning out `OpenAI Chat Model - GPT`. Everything else from v1
(node choice, wiring topology, system-prompt change, docs change) is
unchanged and still applies -- this is a narrow amendment, not a redesign.

### New node

**`OpenAI Chat Model - Guardrails`** (`@n8n/n8n-nodes-langchain.lmChatOpenAi`,
typeVersion 1.3)
- Same `model` (`gpt-5-mini`) and `credentials` (`llmOpenAiApiCred` / "OpenAI")
  as `OpenAI Chat Model - GPT` -- same underlying OpenAI credential, but its
  own node instance, so the two AI nodes (agent, guardrail) no longer share
  one model node's output.
- `notes`: explains it exists solely to back `Guardrails - Screen User
  Input`'s classifier, mirrors `OpenAI Chat Model - GPT`'s credential setup,
  and cites task R6.
- Position: placed near `Guardrails - Screen User Input` (below it on the
  canvas), the same relationship `OpenAI Chat Model - GPT` has to the agent.

### Wiring change

- Remove: `OpenAI Chat Model - GPT --ai_languageModel--> Guardrails - Screen
  User Input` (the v1 fan-out).
- `OpenAI Chat Model - GPT` reverts to its original single connection, to
  `AI Agent - Currency Assistant` only.
- Add: `OpenAI Chat Model - Guardrails --ai_languageModel--> Guardrails -
  Screen User Input`.

Nothing else in the graph changes: `Guardrails - Screen User Input`'s own
`classify` parameters, its Pass/Fail routing, `Set - Format Guardrail
Refusal`, and the trimmed agent system prompt from v1 all stand as-is.

### Docs change
`docs/workflows/chat-agent/README.md`'s "## Guardrail" section (added in v1)
currently says the guardrail "reuses `OpenAI Chat Model - GPT` ... so no
separate credential is needed" -- update that sentence to describe the new
dedicated `OpenAI Chat Model - Guardrails` node instead (still no *new*
credential, since it points at the same pre-existing OpenAI credential; only
the node instance is new). The top diagram gains the new model node under
the Guardrails branch, mirroring how `OpenAI Chat Model - GPT` is already
shown under the agent.

### Out of scope
- No credential change -- both model nodes reference the same
  `llmOpenAiApiCred`/"OpenAI" credential id.
- No change to which guardrail checks are enabled, threshold values, or the
  custom `topicalAlignment` prompt text.
