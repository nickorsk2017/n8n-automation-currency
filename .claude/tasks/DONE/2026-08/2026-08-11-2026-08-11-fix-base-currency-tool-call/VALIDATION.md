# VALIDATION — 2026-08-11-2026-08-11-fix-base-currency-tool-call

## v1

result: PASS

- A1: PASS. `Code - Compute Conversion` guard now `rows.length === 0 &&
  (from !== baseCurrency || to !== baseCurrency)`. Verified live (execution
  95): EUR->USD with a rowless lookup returns `NO_RATE_DATA`, not the prior
  `UNKNOWN_CURRENCY`.
- A2: PASS. Verified live (execution 96): EUR->GBP with a non-empty lookup
  (EUR row present, GBP absent) still returns `UNKNOWN_CURRENCY`. Guard change
  does not affect this path.
- A3: PASS. `AI Agent - Currency Assistant.systemMessage` Rule 1 now states
  the always-call-the-tool instruction applies with no exception for
  base-currency (USD) legs, naming the specific rationalization to avoid
  ("trivial"/"rate 1"). Verified live (execution 91): "Convert 100 EUR to USD"
  triggered a `convert_currency` tool call rather than a self-computed answer.
- A4: PASS. `docs/workflows/chat-agent/README.md` NO_RATE_DATA row and Rule 1
  quote updated to match the shipped behavior/wording; no task/harness
  references were added to `docs/` (the one task reference is inside the
  workflow JSON `notes`, matching this file's existing convention, not in
  `docs/`).
- A5: PASS. No secrets in the diff; touched nodes keep descriptive typed names
  and updated `notes`.
- A6: PASS. EXEC.md records 4 real n8n MCP executions (95, 91, 93, 96)
  covering R4(a)/(b)/(c) plus a direct A2 check, with inputs/outputs quoted.

## Scope/constraint check
- Only `workflows/ai-chat-currency-agent.json` and
  `docs/workflows/chat-agent/README.md` touched; Workflow 1 and its docs
  untouched. Matches TASK.md Constraints.
- Fix is prompt-level for R2, per the grounded no-`tool_choice` constraint;
  no node-parameter attempt was made to force tool use.
- Live `currency_rates` table was not mutated by testing (case (a)/(c) used
  `test_workflow` pin data or the real populated table read-only).

No blocking issues.

STATE: stage=VALIDATED, status=PASS, validation_version=1
