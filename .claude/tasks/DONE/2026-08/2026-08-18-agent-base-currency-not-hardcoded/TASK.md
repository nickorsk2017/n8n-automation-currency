# TASK — 2026-08-18-agent-base-currency-not-hardcoded
owner: Engineer
immutable: true

## Problem
The chat agent's conversion arithmetic assumes the stored rates are quoted against
USD by way of a literal in `Code - Compute Conversion` (`const baseCurrency = 'USD'`),
and the agent system prompt names USD as the base in prose. The loader, by contrast,
exposes its base as an editable field in `Set - Loader Config`. The base currency is
therefore stated in three independent places, only one of which is configurable, while
the `currency_rates` table already carries the authoritative value in its
`base_currency` column. Changing the loader's base would leave the agent dividing by
rates it misinterprets — a silently wrong conversion result, not a visible failure.

## Requirements
- R1: `Code - Compute Conversion` MUST NOT contain a hardcoded base-currency literal.
  The base it reasons about is derived from the data it reads (the `base_currency`
  column of `currency_rates`), or the logic is restructured so that no base constant
  is needed.
- R2: The agent system prompt MUST NOT name a specific base currency code. Its
  instruction to always call `convert_currency` — including for a base-currency leg —
  MUST survive the rewording with equal force.
- R3: Existing behaviour is preserved for a USD-based table whenever the table holds
  rates: cross-rate arithmetic, rate = 1 for the base currency, the `NO_RATE_DATA`
  vs `UNKNOWN_CURRENCY` distinction, staleness reporting, and six-decimal rounding.
- R3a (ratified 2026-08-19, amends R3): an empty table answers every conversion with
  `NO_RATE_DATA`, including a code converted into itself and including what used to
  be the base currency. The tool never answers from no data. This supersedes the
  previous `USD -> USD` success-with-rate-1 on an empty table, which existed only
  because the base was a literal.
- R4: The change is applied to the n8n Cloud instance FIRST (workflow
  `AI Chat Currency Agent`, id `bLflLYfGzORWkjJV`), then re-exported to
  `workflows/ai-chat-currency-agent.json` per the export discipline in root CLAUDE.md.
- R5: Documentation asserting that the agent hardcodes or assumes USD is corrected in
  `docs/` — statements of current behaviour only, no task history.

## Acceptance
- A1: No base-currency literal remains in the agent workflow's Code nodes or system
  prompt; currency codes may appear only as format examples, never as control-flow
  constants.
- A2: On the live Cloud instance, a non-base pair (e.g. 100 EUR to JPY) and a
  base-leg pair (e.g. 50 USD to JPY, and 100 EUR to USD) each return the same
  converted amount and rate as before the change.
- A2a: With no rows returned by the lookup, every conversion reports `NO_RATE_DATA`,
  with no code-into-itself or base-currency exception (R3a).
- A3: `workflows/ai-chat-currency-agent.json` matches the live Cloud workflow after
  the change.
- A4: `docs/` contains no claim that the agent assumes USD.

## Constraints
- Cloud edits go through the n8n MCP `update_workflow`; the live instance is not
  hand-edited in the browser.
- No change to the `currency_rates` schema, to the loader workflow, or to the
  `Data Table - Get Rate Rows` filter — out of scope even if a defect is observed
  there; raise it as a separate task.
- Code-node use stays within the root CLAUDE.md exemption (validation / arithmetic);
  no new Code nodes.
- English only in all artifacts and workflow content.
