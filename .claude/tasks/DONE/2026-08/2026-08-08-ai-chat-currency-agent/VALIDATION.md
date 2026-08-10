# VALIDATION — 2026-08-08-ai-chat-currency-agent

## v1
Checked against TASK.md A1-A9 (workflow id bLflLYfGzORWkjJV,
workflows/2-ai-chat-currency-agent.json):

- A1 PASS: Chat Trigger has initialMessages greeting explaining capability.
- A2 PARTIAL/non-blocking: AI Agent -> OpenAI Chat Model wired via
  ai_languageModel; no literal key anywhere (confirmed by grep). No OpenAI
  credential currently exists in this n8n project (list_credentials shows
  only "freecurrencyapi"), so the node's `credentials` block is empty rather
  than a name/id reference. This mirrors the freecurrencyapi credential
  precedent (created manually by Engineer outside any task, before workflow
  1 could reference it) -- treating as a non-blocking manual follow-up per
  that same precedent, not a requirement-type failure, since fabricating a
  credential without a real key would itself be a violation (no fake
  API keys). Engineer action needed: create credential named "OpenAI"
  (type openAiApi, backed by LLM_OPENAI_KEY) before live chat use.
- A3 PASS: `convert_currency` toolWorkflow node exists, wired ai_tool ->
  Agent, amount/from_currency/to_currency mapped via $fromAI().
- A4 PASS: verified live (exec 24, 25) -- converted_amount, rate, fetched_at
  all present and arithmetically correct (149.5/0.92=162.5; 1/0.78=1.282051).
- A5 PASS (structural): Memory - Chat Window wired ai_memory -> Agent,
  sessionIdType=fromInput (chat-trigger-derived session). Live multi-turn
  chat not exercised (blocked on A2's credential gap) but the wiring itself
  is the correct, documented n8n pattern for follow-up support.
- A6 PASS: live-verified NON_POSITIVE_AMOUNT (exec 27), UNKNOWN_CURRENCY
  (exec 26), NO_RATE_DATA (exec 23, before seeding). INVALID_AMOUNT /
  INVALID_CURRENCY_CODE share the same validated Code node and were
  code-reviewed rather than separately executed -- acceptable, same
  function path already proven live for the sibling NON_POSITIVE_AMOUNT
  check. All four route through the agent's plain-language system-prompt
  mapping (R6) rather than exposing error_code to the user.
- A7 PASS: docs/agent-system-prompt.md (verbatim prompt + rationale),
  docs/convert-currency-tool.md (I/O contract, error table, cross-rate
  formula, bug writeup) both present and substantive.
- A8 PASS: grep for secret-like strings in the exported JSON found none;
  only a note referencing the LLM_OPENAI_KEY env var name.
- A9 PASS: EXEC.md records 5 real (non-simulated) executions against the
  live n8n instance and live currency_rates Data Table, covering the
  success/cross-rate path, the base-currency special case, and 2 of 4
  error codes directly. A genuine bug (zero-item skip causing the tool to
  return nothing on an empty/no-match table) was found via this testing and
  fixed with alwaysOutputData + a synthetic-item guard -- exactly the kind
  of evidence this acceptance criterion exists to produce.

Constraints check: node naming mostly follows `<Kind> - <What>`; the
`convert_currency` node is a deliberate, documented exception (its canvas
name is the literal tool-call name the LLM must invoke, per TASK R3's exact
naming). Code-node use (2x) is justified per root CLAUDE.md (cross-field
validation, cross-rate arithmetic) and documented in each node's `notes`.
All persisted content in English. Workflow 1 untouched. Data Table schema
matches Workflow 1's actual Data Table node config (target file
docs/data-table-schema.md does not exist in the repo -- pre-existing gap
noted in EXEC.md, out of this task's scope to create).

No blocking issues.

result: PASS
validation_version: 1
STATE: stage=VALIDATED, status=PASS, next_actor=Engineer (close via runner.py done)
