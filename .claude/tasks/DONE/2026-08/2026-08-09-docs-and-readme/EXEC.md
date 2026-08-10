# EXEC — 2026-08-09-docs-and-readme

## v1
Created `docs/` with seven pages:
- `README.md` — index, what the system does, the layer model in brief.
- `architecture.md` — layer table, the two n8n stands and why they are not
  interchangeable, the sync diagram, end-to-end data flow.
- `data-table-schema.md` — columns, the `(base_currency, target_currency)` key,
  why upsert, why `fetched_at` sits on the row, why cross rates are derived.
- `workflow-1-rate-loader.md` — flow diagram, UTC schedule, the three failure
  stages with the emitted record, the no-partial-write guarantee, and a short
  "when it fails, what to do".
- `workflow-2-chat-agent.md` — the two entry points, the full tool contract
  (inputs, success shape, all five error codes), the cross-rate formula, the
  `alwaysOutputData` subtlety, the greeting, the complete system prompt.
- `operations.md` — prerequisites, stack commands, credential setup for both
  keys, import/export/drift, reading a failed run, file map.
- `audit.md` — deterministic vs judgement checks, the current check list,
  how to request an audit, and an explicit statement of what is not yet
  automated.

Rewrote `README.md` end to end rather than patching it. The previous version had
grown into setup prose that duplicated what now lives in `docs/operations.md`
and pointed at three files that did not exist. It now carries only what the
brief asks a README to carry — setup, schema rationale, system prompt summary,
trade-offs — plus the layers table, and links into `docs/` for detail.

### Link repair
The three dead links are resolved as planned: `docs/data-table-schema.md` exists
as its own page; the agent system prompt and the tool contract are sections of
`docs/workflow-2-chat-agent.md` and README points at that page instead. No empty
placeholder files were created to satisfy a link.

### Trade-offs section
Split into what was deliberately not built (four items, each with the cost it
accepts stated rather than implied) and what comes next (seven items in build
order). The scheduled audit, Notion drafts and Slack intake appear in the second
list, described as future work — the documentation nowhere implies they run
today.

### Behaviour change documented
The loader's "a failed fetch is now a failed execution" change is recorded in
`docs/workflow-1-rate-loader.md` under failure behaviour and again in
`docs/operations.md` under reading a failed run, which is where someone would
look after seeing a red execution.

### Verification run
- 19 relative markdown links across README and `docs/` — all resolve.
- Grep for harness vocabulary in `docs/` (`R<n>`, `A<n>`, artifact filenames,
  stage names, task ids) — no matches.
- Non-ASCII scan — only typographic arrows and em dashes; all prose is English.

STATE: stage=EXECUTED, next_actor=Validator, exec_version=1
