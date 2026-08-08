# TASK — 2026-08-08-makefile-n8n
owner: Engineer
immutable: true

## Context
`docker-compose.yml` (task `2026-08-08-n8n-docker-compose`, DONE) already
provides a reproducible n8n instance via `docker compose up -d`. Engineer
wants a `Makefile` with short, memorable targets wrapping the common
docker-compose commands, and the README updated to document them so the
Setup section reflects the actual current workflow instead of a generic
"local Docker n8n instance" note.

## Requirements
- R1: Add a `Makefile` at repo root with targets wrapping `docker compose`
  operations against `docker-compose.yml`:
  - `up` — start n8n in the background (`docker compose up -d`).
  - `down` — stop and remove the containers (`docker compose down`).
  - `restart` — restart the running stack.
  - `logs` — follow n8n container logs.
  - `ps` — show container status.
  A `help` target (also the default) that lists available targets with a
  one-line description each.
- R2: Targets must not hardcode or echo any secret value; they only
  orchestrate `docker compose`, which itself reads `.env` per the existing
  compose file.
- R3: Update `README.md` Setup section: replace the generic n8n/Docker
  bullet with a note pointing at `docker-compose.yml` and the new `Makefile`
  targets (e.g. `make up`, `make down`, `make logs`), so a reader knows the
  exact commands to run n8n locally.
- R4: Do not restate full command output or unrelated content in README;
  keep the addition scoped to the Setup section.

## Acceptance
- A1: `Makefile` exists at repo root with `up`, `down`, `restart`, `logs`,
  `ps`, and `help` (default) targets, each calling the corresponding
  `docker compose` command against the root `docker-compose.yml`.
- A2: `make help` (or running `make` with no args) prints target names and
  descriptions, no error.
- A3: No literal secret value appears in `Makefile`.
- A4: `README.md` Setup section documents `docker-compose.yml` +
  `Makefile` usage (at least `make up`/`make down`/`make logs`) in place of
  the old generic Docker bullet.

## Constraints
- English only in all persisted content (per root `CLAUDE.md` language
  rule).
- Touches: `Makefile` (new), `README.md` (edit) — 2 files -> MEDIUM
  complexity, routes through Planner.
