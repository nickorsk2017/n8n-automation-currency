# TASK — 2026-08-09-readme-workflow-folder-links
owner: Engineer
immutable: true

## Requirements
- R1: In the root `README.md`, link to each workflow's documentation
  **directory**, not to individual files inside it. One link per workflow.
- R2: Drop the separate README link to
  `docs/workflows/rate-loader/data-table-schema.md`. It is a page inside the
  loader's directory and is reachable from there; listing it separately makes
  the README track the contents of a directory, which is exactly what it should
  not do.
- R3: Apply the same form to the other places that link to a workflow's
  documentation — `docs/README.md` and `docs/architecture.md` — so the
  convention is uniform rather than applied only where it was noticed.
- R4: Record the rule in root `CLAUDE.md`.

## Acceptance
- A1: `README.md` contains exactly one link per workflow, each pointing at
  `docs/workflows/<name>/`, and no link to a file inside those directories.
- A2: `docs/README.md` and `docs/architecture.md` link to workflow directories
  in the same form.
- A3: Root `CLAUDE.md` states that links to a workflow's documentation address
  the directory, so adding or renaming a page inside it never requires editing
  the linking file.
- A4: Every relative link across `README.md`, `CLAUDE.md` and `docs/**`
  resolves, directories included.

## Constraints
- Four files touched -> MEDIUM.
- Documentation only.
- The Notion mirror remains stale until a sync is requested.
