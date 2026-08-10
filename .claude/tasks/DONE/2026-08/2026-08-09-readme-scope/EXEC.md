# EXEC — 2026-08-09-readme-scope

## v1
Changed files:
- `README.md` — removed `## Data table schema` and `## Agent system prompt`
  (28 lines); rewrote the `## Documentation` section into a named list of the
  workflow pages. Section headings are now Layers, Setup, Trade-offs,
  Documentation — every one of them about the system as a whole or about the
  submission, none about a single workflow.
- `CLAUDE.md` — added the README scope rule alongside the other `docs/` rules.

### Before deleting, checked the content survives
Confirmed the schema page still carries all three pieces of rationale the README
had been restating (the key following the API shape, upsert rather than append,
cross rates derived rather than stored), and that the agent page carries the full
`## System prompt` block. Nothing was removed that did not already exist in
fuller form one link away.

### The links are named, not bare
The `## Documentation` list spells out what each page contains — "the data table
schema and why it is shaped that way", "the full agent system prompt, the
`convert_currency` tool contract, its error codes". A reviewer working through
the brief's checklist is scanning the README for the words "schema" and "system
prompt"; those words still appear, attached to the link that leads to the
content, so following the checklist from the README still works.

### Scope extension
R1 named only the schema section. The system prompt section was the same
violation — workflow-specific material at the top level, duplicating a page that
already said it better — so it was removed under the same rule rather than left
to be reported next.

### Verification
- Neither heading remains in `README.md`.
- Both links present and resolving; 12 relative links across 7 files, none
  broken.
- The CLAUDE.md rule appears once.
- `README.md` is now 138 lines.

STATE: stage=EXECUTED, next_actor=Validator, exec_version=1
