# PLAN — 2026-08-09-docs-and-readme

## v1

### The distinction that decides what goes where
The previous `docs/` was deleted because it restated the harness. That is the
right instinct and the fix is not "write less" but "write a different thing":

- The harness answers **how this came to be** — what was decided, in what order,
  what was rejected, which requirement a node satisfies. It is addressed to an
  auditor and to future actors, and it is versioned.
- `docs/` answers **what exists and how to operate it**. It is addressed to a
  person who has just been handed the system. It has no history; it is rewritten
  in place when the system changes.

Concretely: "a Code node was chosen over three Set nodes because the branches
carry different item shapes" belongs to the harness. "The error branch produces
a record with these four fields, and a failed fetch turns the execution red"
belongs to `docs/`. The same change generates both sentences; they are not
duplicates.

That test also settles R1's exclusion list: no `R<n>`/`A<n>` identifiers, no
stage names, no task ids in `docs/`, because each of those is a pointer into
history rather than a statement about the running system.

### Structure
    docs/README.md              index; what the system is; the layer model
    docs/architecture.md        stands, sync directions, where Claude sits
    docs/data-table-schema.md   currency_rates: columns, key, why
    docs/workflow-1-rate-loader.md   loader: flow, failure behaviour, schedule
    docs/workflow-2-chat-agent.md    agent, tool contract, system prompt, errors
    docs/operations.md          run, import/export, drift, credentials
    docs/audit.md               what an on-demand audit checks today

Seven files rather than one long page, because the README already carries the
submission-level summary and the failure mode to avoid is two documents saying
the same thing at different lengths. README stays the entry point and links in;
`docs/` holds the detail.

### Link repair (R4)
README currently points at three files that were never created. Two of them —
the agent system prompt and the tool contract — are subjects, not documents:
they are properties of workflow 2 and belong in `docs/workflow-2-chat-agent.md`.
Only `data-table-schema.md` earns its own file, because the loader and the agent
both depend on the schema and neither owns it. So: create the schema file, fold
the other two into the workflow-2 page, and repoint README rather than creating
empty files to satisfy the links.

### Layers table (R3)
Five rows: harness, `docs/`, Notion mirror, `workflows/*.json`, Claude + MCP.
Each row states contents and audience. The row that carries the argument is the
last one: the automation layer of this system is Claude driving MCP tools on
request, not a fifth n8n workflow — which is why the audit and documentation
loops exist today as operations rather than as scheduled jobs.

### Trade-offs section (R5)
Two lists, kept apart because they answer different questions. What was
deliberately not built and why (single error convergence point rather than a
persisted errors table; cross-rate arithmetic rather than a wider table; tool
implemented as a second entry point in the same workflow file). What comes next
(scheduled and change-triggered audit; findings as Notion drafts; Slack intake;
`loader_errors` table; staleness warning when rates go cold; tests for the
cross-rate maths). The second list is where the Notion and Slack ambitions are
stated honestly as future work rather than implied to exist.

### R6 placement
The "a failed fetch is now a failed execution" change is operational behaviour,
so it belongs in `docs/workflow-1-rate-loader.md` under failure behaviour and in
`docs/operations.md` where someone would look after seeing a red run — not in
the trade-offs list.

### Verification approach
Link resolution is checked mechanically by extracting every relative markdown
link from README and `docs/` and asserting the target exists. Absence of harness
vocabulary in `docs/` is checked by grep for `R[0-9]`, `A[0-9]`, task-id and
stage-name patterns.

STATE: stage=PLANNED, next_actor=Executor, plan_version=1
