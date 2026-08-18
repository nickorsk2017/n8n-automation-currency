# TASK — 2026-08-18-data-table-by-name
owner: Engineer

## Context
On the Docker stand the `convert_currency` tool failed with
`Data table with name "tU2fbDOMyMnanxzS" not found`, and the agent reported to
the user that rate data was unavailable.

`Data Table - Get Rate Rows` had `dataTableId: {mode: "name", value:
"tU2fbDOMyMnanxzS"}` — the mode was already correct, but the value was a Cloud
instance id rather than a name, so n8n searched for a table literally named
after that id. The node works on no instance at all, including the one the id
came from, because the lookup is by name either way.

`workflows/currency-rate-loader.json` and `workflows/error-logger.json` both
use the table's real name. This was an isolated slip, most likely from picking
the table out of the editor's dropdown.

## Requirements
- R1: `Data Table - Get Rate Rows` references `currency_rates` by name.
- R2: No other resource locator in `workflows/` carries an id in a by-name
  field. Check rather than assume.

## Acceptance
- A1: A conversion question in the chat widget on Docker returns a converted
  amount.
- A2: `workflows/ai-chat-currency-agent.json` matches the published Cloud graph.

## Constraints
- Verification is the Engineer's, in the widget.
