# EXEC — 2026-08-09-docs-restructure

## v1
Moves (via `git mv`, so history follows the files):
- `docs/workflow-1-rate-loader.md` -> `docs/workflows/rate-loader/README.md`
- `docs/workflow-2-chat-agent.md`  -> `docs/workflows/chat-agent/README.md`
- `docs/data-table-schema.md`      -> `docs/workflows/rate-loader/data-table-schema.md`

Deleted: `docs/operations.md`, `docs/audit.md`.

Resulting tree:

    docs/README.md
    docs/architecture.md
    docs/workflows/rate-loader/README.md
    docs/workflows/rate-loader/data-table-schema.md
    docs/workflows/chat-agent/README.md

### `operations.md` content relocated, not discarded
`Makefile` gained a 48-line header covering requirements, first-run setup, why
the timezone variables sit in docker-compose rather than `.env`, both credentials
including why freecurrencyapi must be a stored credential rather than an `$env`
expression on Cloud, the two-stand split, the id-must-match warning for import,
and how to read a red loader run. The per-target `##` help strings remain the
one-line reference. Nothing that a person needs in order to run the system
existed only in the deleted page.

`audit.md` was deleted outright. The check list it held is still described in the
root README's future-work section.

### `docs/README.md`
Reduced to 23 lines: what the section is (current state, not history), where
operational instructions actually live, three links, and the Notion sync rule.
It no longer summarises the pages beneath it.

### Link repair
Eight links pointed at moved or deleted files. Links into deleted pages were not
repointed at a substitute — there is none — they were rewritten to name the
`Makefile` or the root README as appropriate, and the surrounding sentences
adjusted so they still read correctly. Two README sentences that described
`docs/` as containing operations and audit material were rewritten.

### `CLAUDE.md`
Two new sections. **`docs/` rules** states the harness-versus-docs split, the
exclusion list, directory-per-workflow under `docs/workflows/<name>/` with no
numeric prefix, workflow-specific material inside its workflow directory, the
top level reserved for cross-cutting pages, operational instructions in the
Makefile, `docs/README.md` kept short, and links verified mechanically.
**Documentation sync to Notion** states that the repository is the source, that
sync happens on request, that only pages under `N8N Workflows` may be touched,
that unimplemented pages must say so in their first line, and that a `docs/`
restructure leaves the mirror stale until a sync is asked for. The Repository
layout entry for `docs/` was updated to point at these rules rather than listing
contents that had already changed once.

### Verification
- 11 relative links across 7 files (README, CLAUDE.md, all of `docs/**`) — all
  resolve.
- `make help` and `make -n up` still parse after the header addition.
- No harness vocabulary anywhere under `docs/`.
- Both new `CLAUDE.md` sections present exactly once.

### Known consequence
The Notion mirror still has `Operations` and `Auditing the workflows` pages and
the old page names, because it is refreshed on request and no sync was requested
in this task. This is the stale-mirror case the new CLAUDE.md rule requires to be
stated rather than assumed away.

STATE: stage=EXECUTED, next_actor=Validator, exec_version=1
