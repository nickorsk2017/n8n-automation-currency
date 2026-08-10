# TASK — 2026-08-09-docs-restructure
owner: Engineer
immutable: true

## Requirements
- R1: Group workflow documentation under `docs/workflows/`, one directory per
  workflow, dropping the numeric prefix from the names:
  `docs/workflow-1-rate-loader.md` -> `docs/workflows/rate-loader/`,
  `docs/workflow-2-chat-agent.md` -> `docs/workflows/chat-agent/`.
- R2: Move `docs/data-table-schema.md` to
  `docs/workflows/rate-loader/data-table-schema.md`. The schema is written by
  the loader, so it belongs with the loader rather than at the top level.
- R3: Delete `docs/operations.md`. Operational instructions belong next to the
  commands they describe, so the essential content moves into `Makefile` as
  comments and target help text.
- R4: Delete `docs/audit.md`.
- R5: Reduce `docs/README.md` to a short statement of what the section is for
  and how it is synchronised to Notion. It should not restate the contents of
  the pages beneath it.
- R6: Record these rules in the root `CLAUDE.md` so the structure survives
  future work rather than depending on this task being remembered.
- R7: Every link in the repository must still resolve after the move.

## Acceptance
- A1: `docs/workflows/rate-loader/` and `docs/workflows/chat-agent/` exist, each
  with its workflow documentation; `data-table-schema.md` sits under
  `rate-loader/`.
- A2: `docs/operations.md` and `docs/audit.md` no longer exist, and no file
  links to them.
- A3: `Makefile` documents setup, credentials and the drift check well enough
  that deleting `operations.md` loses no instruction a person needs to run the
  system.
- A4: `docs/README.md` is short and describes the section's purpose and the
  Notion sync, without duplicating page contents.
- A5: Root `CLAUDE.md` states the `docs/` layout rules and the
  docs-to-Notion sync rule.
- A6: Every relative link in `README.md` and under `docs/` resolves, verified
  mechanically.

## Constraints
- Multiple files across docs/, Makefile and CLAUDE.md -> MEDIUM.
- Documentation and comments only; no workflow JSON or script behaviour changes.
- The Notion mirror is generated from `docs/` on request and is not updated by
  this task; it will be out of step until a sync is requested.
