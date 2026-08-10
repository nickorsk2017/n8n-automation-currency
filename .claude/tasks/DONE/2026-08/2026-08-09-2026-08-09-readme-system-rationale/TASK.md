# TASK — 2026-08-09-2026-08-09-readme-system-rationale
owner: Engineer
immutable: true

## Requirements
- R1: Add a new subsection to root `README.md` stating the motivation behind
  building a system around the two workflows rather than delivering the
  workflows alone. Cover, in the Engineer's own framing, three problems:
  1. Outside the AI Automation Engineer, nobody knows how the workflows work or
     how to operate them.
  2. A CTO, end users, and other engineers can currently only learn this from
     the repository's documentation — and once an organization has dozens of
     repositories and a larger team, "read the repo" stops scaling.
  3. There is no automated audit of workflows: manual review is slow, and once
     there are hundreds of workflows manual review is close to infeasible;
     automated tests alone are not sufficient either.
  Frame the harness/docs/Notion-mirror/audit system built in this repository as
  a minimal environment addressing these three problems, not as scope creep.
- R2: Content must be about the system as a whole (not workflow-specific), per
  the existing README scope rule in root `CLAUDE.md` — this section belongs in
  README, not under `docs/workflows/<name>/`.
- R3: Do not duplicate `docs/architecture.md` at length. The existing `Layers`
  table and its surrounding paragraph in README already state the mechanism
  (harness / docs / Notion mirror / on-request automation); this new
  subsection states the *why* (the three problems above) and may point at
  `Layers` / `docs/architecture.md` for the *how*, without restating it.
- R4: Written in English, consistent with the root CLAUDE.md language rule.

## Acceptance
- A1: `README.md` contains a new subsection (own heading) stating the three
  problems above and framing the harness/docs/audit system as addressing them.
- A2: No restatement of `docs/architecture.md` mechanism details beyond what is
  needed to point a reader there; no new duplicate source of truth created.
- A3: All relative links added remain resolvable.
- A4: Section content is in English.

## Constraints
- One file touched (`README.md`), no new deps -> LOW.
