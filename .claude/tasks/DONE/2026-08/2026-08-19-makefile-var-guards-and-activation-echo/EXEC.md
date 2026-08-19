# EXEC — 2026-08-19-makefile-var-guards-and-activation-echo

## v1
- `Makefile`: added `require_var` beside `ensure_executable` (marker
  `ERR_MISSING_VAR`, exit 2, message carrying the usage line) and called it as the
  first line of `import` (FILE), `export` (ID, FILE) and `drift` (ID, FILE).
- `scripts/activate_workflow.sh`: prints `Activated workflow '<id>' from <file>.` on
  success and `Workflow '<file>' is not marked active — left inactive.` on the skip
  path. Exit codes untouched.
- Deleted `TODO.md`: its only item was this defect, and an empty TODO file reads as a
  claim that nothing is outstanding.

## v2
Per PLAN v2: `drift`'s recipe now runs under `set -e` with `&&` between steps and a
`trap` for cleanup, and uses `cp` in place of both `mv` calls, so the repository file
is never the sole occupant of a temporary directory that `rm -rf` will remove.

### Checks (sandbox, no n8n stand)
- `make drift`, `make export`, `make import` bare: exit 2, correct variable named,
  `workflows/` byte-identical afterwards (md5 of the whole directory compared before
  and after all three runs).
- `make drift ID=xyz FILE=currency-rate-loader.json`: passes the guard, fails at the
  export step because no container is running, and leaves `workflows/` byte-identical
  — the same invocation shape that destroyed the directory this morning.
- `bash -n scripts/activate_workflow.sh` clean. Its success path needs a live stand and
  is unverified here.
