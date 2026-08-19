# PLAN — 2026-08-19-makefile-var-guards-and-activation-echo

## v1

### Decision 1 — a guard macro, not per-target `if`
Add `require_var` beside `ensure_executable` and call it as the first line of
each affected recipe. The existing macro already establishes the pattern —
greppable marker, message naming the fix, distinct exit code — and reusing it
keeps three targets from drifting apart in wording. Exit 2 distinguishes "you
invoked this wrong" from 126 ("a script is not executable"); both are unmistakably
the Makefile's own refusal rather than a tool's error.
Rejected: validating inside the shell scripts. `export_workflow.sh` already
rejects a wrong argument count, and that did not help — `drift` runs `cp` and
`mv` on `workflows/$(FILE)` *before* the script is ever called, so the damage
window is in the recipe, not in the script. A guard has to sit where the
expansion happens (R1, R2).

### Decision 2 — which targets
`import` (FILE), `export` (ID, FILE), `drift` (ID, FILE). `import-all` and the
`setup-*` targets take no command-line variables and are left alone.

### Decision 3 — activation output
`activate_workflow.sh` prints one line on success and one when the file is not
marked active, both to stdout, before its existing `exit 0`. Nothing else about
the script changes: its silence on success was the only reason a completed
`make import` looked indistinguishable from one where activation never ran (R3).

### Decision 4 — TODO.md
The file's single item is the problem this task fixes, so removing the item
empties it and the file is deleted (R4). A `TODO.md` holding only a heading
invites the next reader to trust it as "nothing outstanding", which is a claim
the repository cannot make.

### Impact map
- `Makefile` — `require_var` macro + three guarded recipes and their help text.
- `scripts/activate_workflow.sh` — two echo lines.
- `TODO.md` — deleted.

### Risks
- R-1: a guard that fires on a legitimate invocation would break `import-all`,
  which calls the scripts directly rather than through the guarded targets.
  Verified by reading: `import-all` does not use `$(FILE)`.
- R-2: the sandbox has no n8n stand, so guarded *failure* paths are testable
  end to end but the success paths are not. A2 is verified only as far as the
  guard passing control on; the export itself needs the operator's stand.

### Sequence
1. Add the macro; guard `import`, `export`, `drift`.
2. Run each target bare; confirm exit code, message, and that `workflows/` is
   byte-identical afterwards.
3. Add the two echo lines; re-check the script parses and its exits are unchanged.
4. Delete `TODO.md`; grep the repository for references to it.

## v2
Amends v1 after the incident that closed
2026-08-19-recover-deleted-workflows-dir. v1's premise was wrong in one respect: a
missing variable was not the only unsafe property of the `drift` recipe, and `cp`
refusing a directory did not stop the chain — the following `mv` still ran and moved
`workflows/` into a directory the recipe then deleted.

### Decision 5 — the recipe must not continue past a failed step
Chain `drift`'s commands with `&&` under `set -e` instead of `;`, so no step runs on
the wreckage of a failed one. Additionally, replace the two `mv` calls with `cp`: the
sequence's purpose is to compare a file against a fresh export, and moving the
repository file out of the tree means there is a window in which it exists nowhere in
`workflows/`. With `cp`, the file is always on disk, and the worst case of an
interrupted run is that it briefly holds the exported copy rather than being absent.
A temporary directory removed by `rm -rf` should never be the only home of a
repository file.

### Impact map (added)
- `Makefile` — the `drift` recipe body.
