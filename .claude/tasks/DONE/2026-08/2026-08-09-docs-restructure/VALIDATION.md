# VALIDATION — 2026-08-09-docs-restructure

## v1
- **A1 PASS.** `docs/workflows/rate-loader/` and `docs/workflows/chat-agent/`
  each hold a `README.md`, and `data-table-schema.md` sits under `rate-loader/`.
  Numeric prefixes are gone from the doc paths while `workflows/*.json` keeps
  its numbering, which is the right split — the number encodes load order for
  the exported artifacts, not for the prose.
- **A2 PASS.** `docs/operations.md` and `docs/audit.md` are gone, and a
  repository-wide grep for either filename returns nothing.
- **A3 PASS.** The Makefile header covers requirements, first-run setup,
  credentials for both providers with the Cloud `$env` caveat, the two stands,
  the import-id warning and how to read a red loader run. Checked against the
  deleted page section by section: no instruction was lost. `make help` and
  `make -n up` still parse, so the header did not break the file.
- **A4 PASS.** `docs/README.md` is 23 lines and states purpose, where
  operational instructions actually live, three links and the Notion sync rule.
  It no longer restates the pages beneath it.
- **A5 PASS.** `CLAUDE.md` carries `## \`docs/\` rules` and
  `## Documentation sync to Notion`, each appearing exactly once, and the
  Repository layout entry now points at them instead of listing contents that
  have already changed once.
- **A6 PASS.** 11 relative links across 7 files resolve; none broken.

### Assessment beyond acceptance
Deleting a page and relocating its content are different operations, and this
task did both deliberately: `operations.md` moved, `audit.md` went. Worth noting
because the Makefile header is now load-bearing documentation — if it is ever
trimmed as "just comments", setup instructions disappear with it. The new
CLAUDE.md rule stating that operational instructions belong in the Makefile is
what protects against that.

Links into deleted pages were rewritten rather than repointed at a nearest
surviving page. That is the honest handling: a link to `operations.md` meant
"the operational detail is over there", and the replacement sentence has to name
where that detail actually went, not the closest thing still standing.

The CLAUDE.md rules are written as constraints on future work rather than as a
description of the present tree, so adding a third workflow will not require
editing them.

### Known limitation (documented, non-blocking)
The Notion mirror is stale: it still carries `Operations` and
`Auditing the workflows` pages and the pre-move page names. No sync was
requested in this task and the sync rule is explicitly on-request, so this is
expected rather than a defect — and the new CLAUDE.md rule requires exactly this
statement rather than silence. It resolves on the next requested sync.

No blocking issues.

result: PASS
validation_version: 1
STATE: stage=VALIDATED, status=PASS, next_actor=Engineer (close via runner.py done)
