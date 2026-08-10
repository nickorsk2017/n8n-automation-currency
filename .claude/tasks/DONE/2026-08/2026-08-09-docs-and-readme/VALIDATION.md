# VALIDATION — 2026-08-09-docs-and-readme

## v1
- **A1 PASS.** `docs/` holds an index plus six topic pages covering the layer
  model, both stands, the schema, both workflows, operations and the audit.
  Grep for harness vocabulary — requirement ids, acceptance ids, artifact
  filenames, stage names, dated task ids — returns nothing. The separation the
  plan set out is actually held: `docs/` states what the system does, the
  harness keeps why and when.
- **A2 PASS.** The layers table is present in README, in English, with contents
  and audience per row, and repeated in `docs/architecture.md` where the detail
  belongs.
- **A3 PASS.** 19 relative links across README and `docs/` were extracted and
  resolved mechanically; none broken. The three previously dead links are gone —
  `docs/data-table-schema.md` now exists, and the prompt and tool-contract links
  point at `docs/workflow-2-chat-agent.md` where that content actually lives.
  No placeholder files were created to game the check.
- **A4 PASS.** README carries all four items the brief requires: setup, data
  table schema rationale, agent system prompt (summarised, with the full text
  one link away), and trade-offs.
- **A5 PASS.** Non-ASCII scan returns only typographic arrows and em dashes.
  All prose is English.

### Assessment beyond acceptance
The trade-offs section states the cost each decision accepts rather than only
the decision — "cross rates derived, not stored" is followed by the float
precision consequence, and the single error convergence point is followed by
what it gives up (no queryable failure history). That is the form the brief is
actually asking for.

`docs/audit.md` ends by stating plainly that nothing is scheduled yet. Given the
same document lists what an audit checks, that sentence is what keeps the page
honest rather than aspirational; without it the page reads as a description of a
running system.

The README rewrite rather than patch was the right call: the previous file had
absorbed operational detail that now belongs in `docs/operations.md`, and
leaving both would have produced exactly the duplication that got the first
`docs/` deleted.

### Note for the closing checklist (not blocking)
README no longer references a `screenshots/` directory, because none exists.
The brief requires execution and conversation screenshots as deliverables, so
this remains an open manual item for the Engineer rather than a documentation
defect — flagged here so it is not lost between tasks.

No blocking issues.

result: PASS
validation_version: 1
STATE: stage=VALIDATED, status=PASS, next_actor=Engineer (close via runner.py done)
