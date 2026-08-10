# VALIDATION — 2026-08-09-readme-scope

## v1
- **A1 PASS.** Neither `## Data table schema` nor `## Agent system prompt`
  remains. The surviving headings — Layers, Setup, Trade-offs, Documentation —
  each pass the test the rule sets: they concern the system as a whole or the
  submission, not one workflow.
- **A2 PASS.** Both links present, and described rather than bare. The phrases a
  reviewer would search the README for ("schema", "system prompt") still appear,
  attached to the link that leads to them.
- **A3 PASS.** Verified before deletion, not assumed: the schema page carries
  all three rationale points the README had restated, and the agent page carries
  the full system prompt block. Nothing left the repository.
- **A4 PASS.** The README scope rule is in `CLAUDE.md`, grouped with the other
  documentation rules rather than in Repository layout — correct placement, since
  it constrains what may be written rather than describing the current tree.
- **A5 PASS.** 12 relative links across README, CLAUDE.md and `docs/**` all
  resolve.

### Assessment beyond acceptance
The tension in this task was real and worth recording: the brief asks the README
to contain the schema rationale and the system prompt, while the structural rule
says workflow-specific material must not live there. Resolving it by keeping
named pointers rather than deleting outright satisfies both — one authoritative
copy, still reachable in one click from the submission entry point. Deleting the
sections with no replacement would have satisfied the rule and quietly failed the
brief.

Extending the rule to the system prompt section without being asked is the right
call here: it was the same violation of the same rule, and fixing only the
section that was pointed at would have left the README half-corrected.

### Known limitation (unchanged from the previous task)
The Notion mirror is still stale and now diverges further — it carries the old
page structure and the README-level schema content. Resolves on the next
requested sync.

No blocking issues.

result: PASS
validation_version: 1
STATE: stage=VALIDATED, status=PASS, next_actor=Engineer (close via runner.py done)
