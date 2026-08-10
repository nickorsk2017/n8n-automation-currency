# EXEC — 2026-08-09-2026-08-09-readme-system-rationale

## v1
Changed files:
- `README.md` — inserted a new `## Why a system, not just two workflows`
  subsection between the intro and `## Layers`. States the three problems
  (R1.1-R1.3: only the builder understands the system; "read the repo" does
  not scale past one repository/team; no automated audit at scale) and frames
  the harness/docs/Notion-mirror/audit stack as a minimal environment
  addressing them, then points to `Layers` and `docs/architecture.md` for the
  mechanism rather than restating it.

### Placement
Put the section before `Layers` rather than after: `Layers` and the paragraph
under it already answer "how" (the mechanism); the new section answers "why"
and reads better as the thing a skeptical reviewer hits first, before the
table.

### R3 (no duplication)
The new section names the three problems and states the conclusion; it does
not restate the two-stand data flow, the drift check, or any mechanism detail
already in `docs/architecture.md` — those stay linked, not repeated.

### Verification
- Both references used (`Layers`, `docs/architecture.md`) already exist as a
  heading in the same file and an existing working link respectively; no new
  link target introduced.
- Section content is English throughout.

STATE: stage=EXECUTED, next_actor=Validator, exec_version=1
