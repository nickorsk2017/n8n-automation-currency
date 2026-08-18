# TASK — 2026-08-18-shared-error-logging-workflow
owner: Engineer
immutable: true

## Requirements
- R1: Create a new, standalone n8n workflow whose sole purpose is centralized
  error logging: it receives an error record via an Execute Workflow Trigger
  and writes one row to a dedicated Data Table. It must be generic enough for
  any workflow in this repository to call, not specific to the chat agent.
- R2: Define the Data Table schema for this log (at minimum: a timestamp,
  which source workflow/node raised the error, an error stage/context label,
  and the error message). Create the Data Table via the n8n MCP tools.
- R3: In `workflows/ai-chat-currency-agent.json`, replace `NoOp - Log Agent
  Error` with a node that calls the new logging workflow (Execute Workflow),
  passing the AI Agent's error context, and preserve the existing downstream
  connection to `Set - Format Agent Error`.
- R4: In the same file, replace `NoOp - Log Tool Error` with a node that calls
  the new logging workflow, passing the tool-input validation error context,
  and preserve the existing downstream connection to `Stop And Error - Invalid
  Input`.
- R5: The call from each replaced node to the logging workflow must reference
  it by a fixed workflow id chosen once (Execute Workflow's resource locator
  has no by-name mode), per the "n8n conventions" section of root CLAUDE.md.
  Check the node's actual type definition before choosing the resource-locator
  mode.
- R6: Follow root CLAUDE.md's n8n conventions: descriptive `<Kind> - <What>`
  node names, a `notes` value on every non-obvious node (including why the
  Execute Workflow call exists and what fixed id it targets), no Code nodes
  where a built-in suffices, and no secrets/credentials literals in exported
  JSON.
- R7: Build and verify both the new workflow and the two node replacements on
  the dev stand (n8n Cloud) via the n8n MCP connector, per
  `docs/architecture.md`'s data-flow model — the MCP connector is the only
  path to that stand.
- R8: Re-export the new workflow to a new file under `workflows/` and
  re-export the updated `workflows/ai-chat-currency-agent.json`, per the root
  CLAUDE.md "Export discipline" section.
- R9: Add a `docs/workflows/<name>/README.md` for the new workflow (schema,
  expected input contract, who calls it), following the existing `docs/`
  rules (one directory per workflow, no task/requirement ids, no numeric
  prefix). Link it from `docs/architecture.md` where the data-flow model is
  described, and from `docs/workflows/chat-agent/README.md` where the two
  replaced nodes are documented, if they are documented there.

## Acceptance
- A1: A new workflow file exists under `workflows/` implementing the Data
  Table write described in R1-R2, importable independently of the other two
  workflows.
- A2: `workflows/ai-chat-currency-agent.json` no longer contains `NoOp - Log
  Agent Error` or `NoOp - Log Tool Error`; both are replaced by Execute
  Workflow nodes targeting the new workflow's fixed id, with the pre-existing
  downstream connections (`Set - Format Agent Error`, `Stop And Error -
  Invalid Input`) intact.
- A3: Live dev-stand workflows (n8n Cloud, via MCP) match the exported JSON —
  no drift between what MCP reports and the repo files.
- A4: New nodes carry descriptive names and `notes`; no literal secrets appear
  in any exported JSON.
- A5: `docs/workflows/<name>/README.md` exists and is linked per R9; no
  task/requirement ids or stage names appear in it.

## Constraints
- Multi-file change (new workflow JSON, `workflows/ai-chat-currency-agent.json`,
  new docs page, possible links from `docs/architecture.md` and
  `docs/workflows/chat-agent/README.md`) -> MEDIUM.
- Out of scope: wiring `workflows/currency-rate-loader.json` (its error branch
  already throws via `Stop and Error - Fail Loader Run` and is not part of
  this request) and syncing the prod stand (self-hosted Docker) — that is a
  separate `make import`/export task per `docs/architecture.md`.
- No new external dependencies or credentials.
