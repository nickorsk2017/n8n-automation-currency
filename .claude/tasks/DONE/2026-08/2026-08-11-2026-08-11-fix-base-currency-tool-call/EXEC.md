# EXEC — 2026-08-11-2026-08-11-fix-base-currency-tool-call

## v1

### Changes
- `workflows/ai-chat-currency-agent.json`:
  - `Code - Compute Conversion`: NO_RATE_DATA guard changed from
    `rows.length === 0 && from !== baseCurrency && to !== baseCurrency` to
    `rows.length === 0 && (from !== baseCurrency || to !== baseCurrency)`
    (P1/R1). Added an inline comment explaining why. `notes` updated to
    reference this task's R1.
  - `AI Agent - Currency Assistant`: `options.systemMessage` Rule 1 extended
    with an explicit base-currency (USD) clause (P2/R2). `notes` updated to
    record the grounded fact that `@n8n/n8n-nodes-langchain.agent` has no
    `tool_choice` parameter, so this is prompt-level only.
  - Applied live via `update_workflow` (workflowId `bLflLYfGzORWkjJV`) first,
    then re-exported the same two edits into the repo JSON so both match
    (root CLAUDE.md export discipline).
- `docs/workflows/chat-agent/README.md`: `NO_RATE_DATA` table row updated to
  describe the base-currency-leg case; Rule 1 quoted text updated verbatim to
  match the new systemMessage; added one sentence noting the Agent node has no
  tool-forcing option (R3).

### Test evidence (R4)
Live n8n MCP executions against workflow `bLflLYfGzORWkjJV` (`currency_rates`
table left untouched throughout — case (a) used pinned test data, not a live
table mutation):
- (a) `execution 95`, `test_workflow` on
  `Execute Workflow Trigger - Convert Currency Tool` with
  `{amount:100, from_currency:'EUR', to_currency:'USD'}` and
  `Data Table - Get Rate Rows` pinned to a rowless result (simulating an empty
  `currency_rates` table): `Code - Compute Conversion` returned
  `{success:false, error_code:'NO_RATE_DATA', message:'No exchange rate data
  has been loaded yet...'}` — was `UNKNOWN_CURRENCY` before the fix. Confirms
  A1.
- (b) `execution 91`, chat input `"Convert 100 EUR to USD"` against the real
  (populated) table: agent called `convert_currency` with
  `{amount:100, from_currency:'EUR', to_currency:'USD'}` and replied "100 EUR
  is 115.46142 USD, using an exchange rate of 1.154614 (fetched at
  2026-08-11T06:00:24.172Z)." Confirms the tool is still called for a
  base-currency leg (R2) and that a populated table still succeeds (A1
  regression check).
- (c) `execution 93`, chat input `"Convert 100 EUR to JPY"` (neither leg is
  base currency): agent called the tool and replied "100 EUR ≈ 18,374.53 JPY.
  The rate used was 1 EUR = 183.745328 JPY, last fetched on 2026-08-11 at
  06:00:24 UTC." — unaffected by the guard change, confirms A2/no regression.

### Notes
- `update_workflow` returned one pre-existing, unrelated validation warning on
  `OpenAI Chat Model - GPT` (`builtInTools` field), not touched by this task
  and not introduced by these edits.
- No secrets touched; no new nodes/dependencies; scope stayed within the two
  files named in TASK.md Constraints.

STATE: stage=EXECUTED, next_actor=Validator, exec_version=1

### Supplemental test (A2 direct verification)
- `execution 96`, `test_workflow` on
  `Execute Workflow Trigger - Convert Currency Tool` with
  `{amount:100, from_currency:'EUR', to_currency:'GBP'}` and
  `Data Table - Get Rate Rows` pinned to one row (`EUR`, non-empty result):
  `Code - Compute Conversion` returned `{success:false,
  error_code:'UNKNOWN_CURRENCY', message:'"GBP" is not a supported currency
  code.'}` — confirms a non-empty lookup result with a genuinely unsupported
  non-base currency still reports UNKNOWN_CURRENCY, not NO_RATE_DATA (A2).
