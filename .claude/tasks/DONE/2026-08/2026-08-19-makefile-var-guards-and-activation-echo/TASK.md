# TASK — 2026-08-19-makefile-var-guards-and-activation-echo
owner: Engineer
immutable: true

## Requirements
- R1: Every Makefile target that requires a variable on the command line refuses
  to run any command in its recipe when that variable is empty, and says which
  one is missing and how the target is invoked.
- R2: The refusal is a distinct, greppable failure — the same shape as the
  existing `ERR_SCRIPT_NOT_EXECUTABLE` guard — not a command that happens to
  fail downstream.
- R3: A successful activation prints one line naming the workflow it activated;
  a file not marked active says so rather than passing silently, so a `make
  import` / `import-all` run shows what did and did not become active.
- R4: `TODO.md` no longer carries the item this task resolves. If that leaves it
  with no items, the file is deleted rather than kept as an empty heading.

## Acceptance
- A1: `make drift`, `make export` and `make import` with no variables each exit
  non-zero having created, copied, moved or deleted nothing, and name the
  missing variable.
- A2: `make drift ID=x FILE=y` still reaches the export script (the guard does
  not change behaviour once variables are present).
- A3: `scripts/activate_workflow.sh` prints one line on success and one on skip;
  its exit codes are unchanged.
- A4: `TODO.md` is gone; no other file references it.

## Constraints
- Guards live next to the targets they protect, in the Makefile, per the root
  CLAUDE.md rule that operational instructions belong there.
- No change to what any target does once its variables are supplied.
