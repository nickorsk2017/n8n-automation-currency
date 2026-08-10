# TASK — 2026-08-09-readme-scope
owner: Engineer
immutable: true

## Requirements
- R1: Remove the `## Data table schema` section from the root `README.md`. The
  schema belongs to one workflow and is already documented at
  `docs/workflows/rate-loader/data-table-schema.md`; restating its rationale in
  the README puts workflow-specific material at the top level.
- R2: Apply the same rule to `## Agent system prompt`, which is
  workflow-specific in exactly the same way and already documented at
  `docs/workflows/chat-agent/README.md`. Extending the rule rather than fixing
  only the section that was pointed at, so the README does not immediately
  reacquire the problem.
- R3: The README must still lead a reader to both, since the test brief expects
  the schema rationale and the agent system prompt to be findable from the
  submission entry point. Replace the sections with named links, not with
  silence.
- R4: Record the rule in root `CLAUDE.md`: the README states what the system is,
  how to set it up and its trade-offs, and links to `docs/` for anything
  specific to a single workflow.

## Acceptance
- A1: `README.md` contains no `## Data table schema` and no
  `## Agent system prompt` section.
- A2: `README.md` links to `docs/workflows/rate-loader/data-table-schema.md` and
  to `docs/workflows/chat-agent/README.md` with enough context that a reviewer
  looking for the schema rationale or the system prompt knows to follow them.
- A3: No content is lost from the repository — everything removed from README
  already exists, in fuller form, in the linked pages.
- A4: Root `CLAUDE.md` states the README scope rule.
- A5: Every relative link in `README.md`, `CLAUDE.md` and `docs/**` resolves.

## Constraints
- Two files touched (README.md, CLAUDE.md) -> MEDIUM.
- Documentation only.
- The Notion mirror remains stale until a sync is requested.
