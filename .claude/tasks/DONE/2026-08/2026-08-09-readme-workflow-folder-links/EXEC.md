# EXEC — 2026-08-09-readme-workflow-folder-links

## v1
Changed files:
- `README.md` — the two workflow entries in `## Documentation` now point at
  `docs/workflows/rate-loader/` and `docs/workflows/chat-agent/`. The separate
  link to `data-table-schema.md` is gone; what it described is folded into the
  loader entry's sentence, so the reader still learns the directory contains the
  schema rationale without the README naming the file.
- `docs/README.md` — both workflow entries changed to directory links.
- `docs/architecture.md` — the loader reference changed to a directory link.
- `docs/workflows/rate-loader/data-table-schema.md` — its cross-reference to the
  agent changed from `../chat-agent/README.md` to `../chat-agent/`.
- `CLAUDE.md` — new rule stating that anything outside a workflow's directory
  links to the directory, with the reason: a link to a page inside binds the
  linking file to that directory's contents, so pages cannot be added, renamed or
  split without breaking links elsewhere.

`docs/architecture.md` keeps its `.md` link because it is a top-level page, not a
workflow directory — the rule is about workflow documentation, not about links in
general.

### Verification
- README has exactly one link per workflow, both to directories, none to a file
  inside one.
- Grep across `README.md`, `CLAUDE.md`, `docs/README.md` and
  `docs/architecture.md` for a `workflows/<name>/<file>.md` pattern: no matches.
- 11 relative links across 7 files, 6 of them directories, all resolve.

### Cost worth recording
The schema rationale and the system prompt are now two clicks from the README
rather than one. Each README entry names what is in the directory, so a reviewer
scanning for "system prompt" or "schema" still sees those words attached to the
link that leads there.

STATE: stage=EXECUTED, next_actor=Validator, exec_version=1
