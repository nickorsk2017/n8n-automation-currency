# TASK — 2026-08-09-docs-and-readme
owner: Engineer
immutable: true

## Requirements
- R1: Create `docs/` as human documentation of **how the system works now**.
  Deliberately excluded: task ids, requirement ids, stage history, design
  alternatives considered and rejected. That material is the harness's job and
  already lives in `.claude/tasks/`; duplicating it into `docs/` is what caused
  the previous `docs/` to be deleted as redundant.
- R2: Cover the whole system, not only the two workflows: the layer model, both
  n8n stands and how they stay in sync, the data table, each workflow, the
  conversion tool contract, the agent system prompt, and the on-demand audit
  that Claude performs via MCP.
- R3: Add a layers table to the root README, in English, naming for each layer
  what it contains and who it is for.
- R4: Repair the root README's dead links. It currently points at
  `docs/data-table-schema.md`, `docs/agent-system-prompt.md` and
  `docs/convert-currency-tool.md`, none of which exist; every documentation link
  in README must resolve to a file in this repo.
- R5: Write the README trade-offs section the test brief asks for: what was
  deliberately not built, and what would be built next with more time —
  including the automated audit, Notion-backed documentation and Slack intake
  that are today manual, on-request Claude operations.
- R6: Document the behaviour change from the error-logging task: a
  freecurrencyapi outage now produces a failed execution rather than a silently
  successful one.

## Acceptance
- A1: `docs/` contains an index plus per-topic files covering R2, and contains
  no task ids, requirement ids (`R1`, `A1`) or harness stage names.
- A2: README contains the layers table in English.
- A3: Every relative link in README and in `docs/` resolves to an existing file,
  verified mechanically.
- A4: README documents setup, data table schema rationale, the agent system
  prompt and trade-offs — the four items the brief requires of it.
- A5: All documentation is in English, per the language rule in root CLAUDE.md.

## Constraints
- New `docs/` directory plus README edits -> MEDIUM.
- Documentation only; no workflow JSON, script or configuration behaviour
  changes in this task.
- Content must describe the system as it stands after the error-logging and
  export/sync tasks, not as it was before them.
