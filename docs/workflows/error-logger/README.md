# Workflow — Error Logger

File: `workflows/error-logger.json`

A shared, generic sub-workflow that any workflow in this repository can call
to record a failure. It has no logic of its own beyond writing one row to a
Data Table — the intent is a single place errors land, instead of each
workflow inventing its own ad-hoc logging node.

```
Execute Workflow Trigger - Log Error Entry
   └─ Data Table - Insert Error Row
```

## Contract

Callers reach this workflow through an `Execute Workflow` node (`source:
database`, `workflowId` in `id` mode — the resource locator has no by-name
option, so callers pin the fixed id and record it in their own node's
`notes`).

**Input**

| Field | Type | Notes |
|---|---|---|
| `source_workflow` | string | Name of the calling workflow |
| `context` | string | Which node or branch raised the error |
| `message` | string | Human-readable error message |

No timestamp field is part of the contract — the `error_log` Data Table's own
`createdAt` system column is the record's timestamp, so callers don't need to
generate one.

## `error_log` Data Table

| Column | Type | Notes |
|---|---|---|
| `source_workflow` | string | |
| `context` | string | |
| `message` | string | |
| `createdAt` | (system) | Row insertion time; doubles as the error timestamp |

## Current callers

`ai-chat-currency-agent` calls this workflow from two places — see
`docs/workflows/chat-agent/` for where each call sits in that workflow's
graph and what `context`/`message` each one sends.

## Docker stand

On the self-hosted Docker stand, `make setup-data-table` creates `error_log`
(alongside `currency_rates`) if it doesn't already exist, and `make
import-all` imports this workflow along with the others. Import order
doesn't matter here: an `Execute Workflow` node only stores the target
`workflowId`, resolved when the caller actually runs, not at import time —
so `ai-chat-currency-agent` and `error-logger` can be imported in either
order as long as both exist before anyone triggers the chat agent's error
branches.
