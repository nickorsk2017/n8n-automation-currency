# VALIDATION — 2026-08-18-guardrails-node-extraction

## v1
Checked against TASK.md R1-R5 / A1-A4, workflows/ai-chat-currency-agent.json
and docs/workflows/chat-agent/README.md (live instance bLflLYfGzORWkjJV
confirmed reachable via search_workflows for cross-reference; not written to
-- see note below).

- R1 PASS: `Guardrails - Screen User Input`
  (@n8n/n8n-nodes-langchain.guardrails, operation=classify) added, wired
  Chat Trigger -> Guardrails -> (Pass) AI Agent, gating the agent's entire
  tool-use path behind the guardrail.
- R2 PASS: "0. (Highest priority...)" paragraph removed verbatim from
  `AI Agent - Currency Assistant.systemMessage`; Rules 1-5 byte-identical to
  before, confirmed by diff-reading the full string. No renumbering was
  needed (PLAN.md's stated no-op) since Rule 0 was never part of the 1-5
  sequence -- internally consistent.
- R3 PASS: `Set - Format Guardrail Refusal` returns the exact fixed string
  "Invalid request. I can only help with currency conversion." on the Fail
  branch, field name `output`, no user-input interpolation anywhere in the
  node, and no connection from the Fail branch back to the agent or
  `convert_currency` -- the tool is structurally unreachable on refusal.
- R4 PASS: node naming follows `<Kind> - <What>` (`Guardrails - Screen User
  Input`, `Set - Format Guardrail Refusal`), consistent with the file's
  existing nodes. Both new nodes carry substantive `notes` explaining
  purpose and referencing this task id, per root CLAUDE.md's n8n
  conventions.
- R5 PASS: docs/workflows/chat-agent/README.md updated -- top diagram shows
  the new node and Pass/Fail branches, a new "## Guardrail" section
  describes it, the system-prompt code block matches the trimmed JSON
  exactly (byte comparison of both Rules 1-5 blocks), and the explanatory
  paragraph below it no longer describes Rule 0 as living in the prompt.

- A1 PASS: `systemMessage` grepped for "Rule 0" and the "Highest priority"
  phrase -- no match. Rules 1-5 present, unchanged, correctly numbered.
- A2 PASS: node exists, wired ahead of the agent (confirmed via connections
  read-back: Chat Trigger -> Guardrails -> [AI Agent, Set - Format Guardrail
  Refusal]), `notes` present and references
  task 2026-08-18-guardrails-node-extraction.
- A3 PASS: docs reviewed end-to-end; no remaining description of the
  refusal as in-prompt-only. The one mention of "Rule 0" left is explicitly
  historical ("that used to be a Rule 0 ... now enforced upstream"), which
  is accurate, not stale.
- A4 PASS: grepped the full JSON for `sk-`, `api.?key`, `secret` (case
  insensitive) -- no matches beyond the pre-existing credential-id
  reference (`llmOpenAiApiCred`), which is a name/id, not a literal key.

Constraints check: built-in Guardrails node used instead of a Code node
(root CLAUDE.md preference). `convert_currency` tool contract untouched
(diffed -- byte-identical). Rules 1-5 content/order unchanged (see R2/R5
above). All new/edited content in English (spot-checked; only non-ASCII
character anywhere in the file is the pre-existing em dash "--", not a
language violation).

Structural verification beyond static reading: `validate_node_config` (n8n
MCP, read-only, no workflow mutation) was run against both new nodes'
exact type/typeVersion/parameters as written in the JSON file --
`Guardrails - Screen User Input` (with its OpenAI Chat Model subnode) and
`Set - Format Guardrail Refusal` both returned `valid: true` against the
live instance's real node schema. This resolves EXEC.md's flagged
uncertainty about whether the guessed `guardrails.jailbreak`/
`guardrails.topicalAlignment` parameter shape was correct -- it is.

Non-blocking, carried forward as a follow-up rather than a blocking issue:
EXEC.md's note that end-to-end `responseMode: streaming` behavior with the
agent no longer being the trigger's immediate successor was not exercised
live. The live instance (bLflLYfGzORWkjJV) still runs the pre-change
version -- this task's scope is the exported JSON + docs (root CLAUDE.md:
"workflows/ JSON is the source of truth for review, not the live n8n
instance"), and deploying/re-importing it is a separate step outside this
task's Read/Write Matrix. Recorded as a manual follow-up: re-import this
file and smoke-test one on-topic and one off-topic chat message before
relying on it in production, the same way the credential-provisioning gap
was carried forward as a follow-up in task 2026-08-08-ai-chat-currency-agent
VALIDATION.md A2.

No blocking issues.

result: PASS
validation_version: 1
STATE: stage=VALIDATED, status=PASS, next_actor=Engineer (close via runner.py done)

## v2
Checked against TASK.md R6/A5 and PLAN.md v2.

- R6 PASS: `OpenAI Chat Model - Guardrails` exists as a separate node
  (`@n8n/n8n-nodes-langchain.lmChatOpenAi`), not a fan-out. `validate_node_config`
  (read-only, live schema) returned `valid: true` for its exact parameters.
- A5 PASS: connection read-back on both the file and the live instance
  confirms `Guardrails - Screen User Input`'s `ai_languageModel` input comes
  from `OpenAI Chat Model - Guardrails` only; `OpenAI Chat Model - GPT` is
  back to its original single connection, to the agent only (no residual
  fan-out).
- Docs (R5 still holds under the amendment): `docs/workflows/chat-agent/
  README.md` diagram and "## Guardrail" section both describe the dedicated
  model node accurately; no stale "reuses OpenAI Chat Model - GPT" text
  remains.
- Live instance: `get_workflow_details` re-fetch after `update_workflow`
  shows the draft with both v1 and v2 changes; `publish_workflow` succeeded,
  `activeVersionId` advanced to `2a3d7238-...`, so the change is live, not
  just drafted, addressing the Engineer's "нужно в cloud версии тоже" request.

Non-blocking, carried forward: the new node has no `credentials` parameter
in the exported file's live counterpart (n8n auto-assigned the only
available OpenAI credential, "n8n free OpenAI API credits", a managed
credential, not the "OpenAI"/`llmOpenAiApiCred` one the exported JSON
references). This is the same pre-existing credential-provisioning gap
already on record for `OpenAI Chat Model - GPT` since task
2026-08-08-ai-chat-currency-agent -- not introduced by this task, not
worsened by it, and out of this task's scope to fix.

No blocking issues.

result: PASS
validation_version: 2
STATE: stage=VALIDATED, status=PASS, next_actor=Engineer (close via runner.py done)
