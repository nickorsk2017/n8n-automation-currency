# VALIDATION — 2026-08-09-readme-workflow-folder-links

## v1
- **A1 PASS.** README's `## Documentation` has one entry per workflow, each
  addressing `docs/workflows/<name>/`, and no link to a file inside either
  directory. The dropped schema link's content survives as description in the
  loader entry, so nothing a reviewer was looking for became invisible.
- **A2 PASS.** `docs/README.md` and `docs/architecture.md` use the same form.
  The cross-reference inside `data-table-schema.md` was also converted, which was
  not required but keeps the convention free of counter-examples.
- **A3 PASS.** The rule is in `CLAUDE.md` with its justification, grouped with
  the README-scope rule it extends.
- **A4 PASS.** 11 relative links across 7 files, 6 of them directories, all
  resolve.

### Assessment beyond acceptance
The convention now matches the one already applied to the Notion mirror — link
the root, not the pages — and the reason is the same in both cases: link to the
fact that will still be true. Three of the last four documentation tasks spent
part of their effort repairing links broken by a move; this rule is what stops
that recurring, and it is worth noting that it was arrived at empirically rather
than adopted on principle.

`docs/architecture.md` correctly keeps a file link, since it is a top-level page
rather than a workflow directory. Worth stating explicitly so the rule is not
later over-applied to every link in the repository.

### Cost accepted, not hidden
The brief expects the schema rationale and the system prompt to be findable from
the README; they are now two clicks away rather than one. The mitigation — each
entry naming what the directory contains — is judged sufficient, but it is a
trade the Engineer chose rather than a free improvement.

### Known limitation (unchanged)
The Notion mirror remains stale and diverges further with each documentation
change. Resolves on the next requested sync.

No blocking issues.

result: PASS
validation_version: 1
STATE: stage=VALIDATED, status=PASS, next_actor=Engineer (close via runner.py done)
