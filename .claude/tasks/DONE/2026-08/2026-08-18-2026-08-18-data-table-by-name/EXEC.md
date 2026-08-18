# EXEC — 2026-08-18-data-table-by-name
owner: Executor
exec_version: 1

## Applied to Cloud `bLflLYfGzORWkjJV`, published `5fbf1ee9`
`Data Table - Get Rate Rows`: `dataTableId.value` `"tU2fbDOMyMnanxzS"` ->
`"currency_rates"`. `mode` was already `"name"` and is unchanged.

## R2 — swept, not assumed
Every `n8n-nodes-base.dataTable` node across `workflows/`:

```
ai-chat-currency-agent  Data Table - Get Rate Rows     mode=name value=currency_rates
currency-rate-loader    Data Table - Upsert Rate Row   mode=name value=currency_rates
error-logger            Data Table - Insert Error Row  mode=name value=error_log
```

No remaining by-name field holding an id. The `Execute Workflow` nodes'
`workflowId` locators legitimately use `mode: "id"` — that node type has no
by-name option, and CLAUDE.md's rule is "the most portable mode the node
actually supports", which for those is a fixed checked-in id.

## Repository
`workflows/ai-chat-currency-agent.json` patched to match.

## NOT verified
A1 is the Engineer's, in the widget on Docker. Cloud has no OpenAI quota.
