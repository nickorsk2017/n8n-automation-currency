# VALIDATION — 2026-08-18-data-table-by-name
## v1
result: PASS
validation_version: 1

- R1 — MET. `Data Table - Get Rate Rows` resolves `currency_rates` by name.
- R2 — MET. All three `dataTable` locators swept; no by-name field holds an id.
  `Execute Workflow` locators keep `mode: "id"` legitimately — that node type
  has no by-name option.
- A1 — MET. Engineer confirmed a conversion now completes in the Docker widget.
- A2 — MET. Repository file matches the published graph.

Note: the Cloud table's id is `tU2fbDOMyMnanxzS`, i.e. the stale value was this
instance's own id. The node was broken on every instance including the one it
came from, because `mode: "name"` never interprets a value as an id.
