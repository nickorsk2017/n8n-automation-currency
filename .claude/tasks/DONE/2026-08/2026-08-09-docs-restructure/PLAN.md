# PLAN — 2026-08-09-docs-restructure

## v1

### The organising principle
Documentation lives next to the thing it documents, and the top level of `docs/`
holds only what is genuinely cross-cutting. Applied to what exists:

- The schema is written by one workflow and read by one tool. It is not a
  top-level concept; it is a property of the loader. Hence
  `docs/workflows/rate-loader/data-table-schema.md`.
- Operational commands are already named in the `Makefile`. A separate page
  restating them is a second place to update and the one that will silently go
  stale, because the person changing a target is looking at the Makefile.
- `docs/README.md` describing every page beneath it duplicates a listing the
  filesystem already provides.

### Directory per workflow, not file per workflow
R1 asks for `rate-loader` as a path segment, and R2 puts a second file inside
it, so each workflow becomes a directory with `README.md` as its main page.
That also means the chat agent can gain its own sub-pages later without another
restructure. Numeric prefixes are dropped from the doc paths; the exported JSON
in `workflows/` keeps its numbering, because there the number encodes load order
for a reader scanning the directory.

Result:

    docs/README.md                                   what this section is, and Notion sync
    docs/architecture.md                             layers, stands, data flow
    docs/workflows/rate-loader/README.md             the loader
    docs/workflows/rate-loader/data-table-schema.md  the table it writes
    docs/workflows/chat-agent/README.md              the agent and its tool

`architecture.md` stays at the top level: it is the one page that is about the
relationship between parts rather than about a part.

### What happens to the deleted content
`operations.md` is not simply dropped. R3's point is placement, not removal, so
the Makefile gains a header comment block covering prerequisites, first-run
setup, the two credentials and how to read a failed loader run, and its target
help strings stay the one-line reference. The test is A3: after deletion, can
someone still set the system up from what remains? If a fact only existed in
`operations.md`, it moves.

`audit.md` is deleted outright per R4. The audit capability is still described
in the root README's future-work list, which is where a reviewer looks; a
dedicated page describing a capability that runs only on request was documenting
an intention more than a system.

### Link repair
Thirteen links point at moving or deleted files, spread across `README.md`,
`docs/README.md`, `docs/architecture.md` and `docs/data-table-schema.md`. Links
into deleted pages are not repointed at a replacement page — there is none —
they are rewritten to name the Makefile or removed with their sentence. Checked
mechanically at the end, not by eye.

### CLAUDE.md (R6)
The existing `docs/` line in Repository layout is one clause describing content
that no longer matches. It is replaced by the structural rules: directory per
workflow under `docs/workflows/`, workflow-specific material inside that
directory, `docs/` top level for cross-cutting material only, `docs/README.md`
kept short, operational instructions in the Makefile, and `docs/` mirrored to
Notion under `N8N Workflows` on request. Stated as rules for future work rather
than as a description of the current tree, so the file does not need editing
every time a page is added.

### Verification
Reuse the link checker from the previous documentation task, extended to walk
`docs/**` recursively rather than `docs/*.md`, plus an assertion that the two
deleted filenames appear nowhere in the repository.

STATE: stage=PLANNED, next_actor=Executor, plan_version=1
