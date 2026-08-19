# TASK — 2026-08-19-todo-file-drift-guard
owner: Engineer
immutable: true

## Requirements
- R1: A `TODO.md` exists at the repository root, holding known problems that are
  acknowledged but not yet fixed, one item each.
- R2: Its first item records the unguarded `drift` / `import` Makefile targets:
  invoked without `ID` / `FILE`, `drift` expands to `cp workflows/` and
  `mv workflows/` and so operates on the whole workflows directory instead of
  one file. Brief, English, enough to act on without re-deriving it.

## Acceptance
- A1: `TODO.md` exists, is English, and states the problem, where it is, and why
  it matters, without prescribing the implementation.
- A2: No other repository file changes.

## Constraints
- The file records the problem only; fixing the Makefile is a separate task.
