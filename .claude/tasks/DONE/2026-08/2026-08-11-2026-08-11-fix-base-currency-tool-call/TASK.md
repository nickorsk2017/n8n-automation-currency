# TASK — 2026-08-11-2026-08-11-fix-base-currency-tool-call
owner: Engineer
immutable: true

## Requirements
- R1: Engineer-reported bug: in `Code - Compute Conversion` (inside `convert_currency`,
  `workflows/ai-chat-currency-agent.json`), the empty-table guard
  `rows.length === 0 && from !== baseCurrency && to !== baseCurrency` is skipped
  whenever either side of the conversion is the base currency (`USD`). Example:
  `EUR -> USD` with an empty `currency_rates` table (loader has not run yet) falls
  through to `findRate('EUR')`, which returns `UNKNOWN_CURRENCY` ("EUR is not a
  supported currency code") instead of `NO_RATE_DATA`. This is misleading: EUR may
  be a perfectly valid, trackable currency, but the tool blames the currency code
  when the real cause is that no rate data has been loaded at all. Fix the guard so
  any conversion leg whose currency is not the base currency, and for which no
  matching row exists because the table has zero rows, is reported as
  `NO_RATE_DATA`, not `UNKNOWN_CURRENCY`. Do not change behavior for the case where
  the table is non-empty but genuinely lacks a row for that specific non-base
  currency (that remains `UNKNOWN_CURRENCY`).
- R2: Engineer-reported concern: the agent may skip calling `convert_currency`
  when one side of the requested conversion is the base currency (`USD`), reasoning
  that a USD leg is "trivial" (rate = 1) and computing the answer itself instead of
  invoking the tool, violating system-prompt Rule 1 ("always call the
  convert_currency tool ... never calculate the conversion yourself"). Confirmed via
  `get_node_types` on `@n8n/n8n-nodes-langchain.agent` (v3.1): this node exposes no
  `tool_choice`/forced-tool-use parameter, so there is no node-level setting that
  can mechanically force a tool call — the only lever available is the system
  prompt. Strengthen `AI Agent - Currency Assistant`'s `systemMessage` (in the same
  workflow JSON) so Rule 1 explicitly and unambiguously covers conversions
  involving the base currency (e.g. `EUR -> USD`, `USD -> JPY`), stating that the
  rule applies with no exception for USD, since the tool — not the model — is the
  only source of the current stored rate and freshness (`fetched_at`/`is_stale`).
- R3: Update `docs/workflows/chat-agent/README.md` to describe both the fixed
  `NO_RATE_DATA` behavior for base-currency legs and the strengthened prompt rule,
  and to record (briefly, as an implementation note, not task history) that the
  n8n Agent node has no mechanical tool-forcing option, so tool-call reliability
  for base-currency legs depends on the system prompt.
- R4: Produce test evidence for: (a) `EUR -> USD` (or similar base-currency leg)
  against an empty `currency_rates` table now returns `NO_RATE_DATA`, not
  `UNKNOWN_CURRENCY`; (b) `EUR -> USD` against a populated table still returns a
  correct `success:true` conversion; (c) a normal non-base-currency-involving
  conversion (e.g. `EUR -> JPY`) is unaffected by the guard change.

## Acceptance
- A1: In `workflows/ai-chat-currency-agent.json`, `Code - Compute Conversion`'s
  empty-table guard returns `NO_RATE_DATA` for any conversion where the table has
  zero matching rows and at least one requested currency is not the base currency,
  regardless of whether the other side is the base currency.
- A2: The guard change does not alter `UNKNOWN_CURRENCY` behavior for a non-empty
  table missing a specific requested currency.
- A3: `AI Agent - Currency Assistant`'s `systemMessage` explicitly states Rule 1
  (always call `convert_currency`) applies even when one side of the conversion is
  the base currency (USD), with no self-calculated exception.
- A4: `docs/workflows/chat-agent/README.md` reflects both changes accurately and
  contains no task/harness references, per root CLAUDE.md `docs/` rules.
- A5: No secrets introduced; node names/notes remain descriptive and typed, per
  root CLAUDE.md n8n conventions.
- A6: EXEC.md records real n8n MCP test executions (or equivalent evidence)
  covering the three cases in R4.

## Constraints
- Scope is limited to `workflows/ai-chat-currency-agent.json` (the
  `Code - Compute Conversion` node and the agent's `systemMessage`) and
  `docs/workflows/chat-agent/README.md`. Do not touch Workflow 1
  (`currency-rate-loader.json`) or its docs.
- Grounded fact (do not re-litigate without new evidence): the
  `@n8n/n8n-nodes-langchain.agent` node (v3.1, confirmed via `get_node_types`) has
  no `tool_choice`/forced-tool-use parameter. Any fix for R2 must be a system-prompt
  change, not a node-parameter change.
- After editing the workflow in the n8n editor/MCP, re-export to
  `workflows/ai-chat-currency-agent.json` per root CLAUDE.md export discipline.
- All persisted content in English, per root CLAUDE.md language rule.
