# TASK — 2026-08-10-2026-08-10-readme-harness-provenance
owner: Engineer
immutable: true

## Requirements
- R1: Add a short note to root `README.md`, near the existing "Why a system,
  not just two workflows" subsection, disclosing the provenance and actual
  cost of the `.claude/` harness: it is reused from another project (adapted
  by copy-paste), not written from scratch for this task; describing this
  project's rules in root `CLAUDE.md` took about 2 minutes. The point is to
  correct a reasonable reviewer assumption that the harness itself consumed
  meaningful time budget from the 4-6 hour brief.
- R2: Keep it factual and brief — a provenance note, not a new subsection with
  its own heading. Do not re-argue the "why" already covered in the existing
  subsection.
- R3: Written in English, per the root CLAUDE.md language rule.

## Acceptance
- A1: README states the harness is reused/adapted from another project, not
  built new for this task.
- A2: README states the CLAUDE.md description took ~2 minutes.
- A3: The note sits with or immediately after the existing "Why a system, not
  just two workflows" subsection, not as a new top-level heading.
- A4: Content is in English.

## Constraints
- One file touched (`README.md`), no new deps -> LOW.
