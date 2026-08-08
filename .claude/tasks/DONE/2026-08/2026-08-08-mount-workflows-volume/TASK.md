# TASK — 2026-08-08-mount-workflows-volume
owner: Engineer
immutable: true

## Context
n8n currently persists all state (including workflows) only inside the named
Docker volume `n8n_data`, per task `2026-08-08-n8n-docker-compose`. Workflow
JSON exported/edited via the n8n UI is not visible in the repo's `workflows/`
directory, which is the source of truth per root `CLAUDE.md` ("Export
discipline"). Engineer wants the container to read/write workflow files
directly from the repo's `workflows/` folder via a bind mount, so changes
made in the n8n editor land on disk in this repo.

## Requirements
- R1: Add a bind mount in `docker-compose.yml` that maps the repo's
  `./workflows` directory into the `n8n` container.
- R2: Keep the existing named volume `n8n_data` mounted at
  `/home/node/.n8n` for n8n's internal state (DB, credentials, settings) —
  do not remove or replace it.
- R3: Do not introduce any literal secret value into `docker-compose.yml`.
- R4: `docker compose config` (or equivalent) must parse the resulting file
  without error.

## Acceptance
- A1: `docker-compose.yml` declares a bind mount from `./workflows` (repo
  root) into the `n8n` container, in addition to the existing `n8n_data`
  named volume.
- A2: `docker compose config` parses the file without error.
- A3: No secret value appears literally in `docker-compose.yml`.
- A4: `workflows/` directory exists at repo root (create if missing) so the
  bind mount source is valid.

## Constraints
- English only in all persisted content (per root `CLAUDE.md` language rule).
- Touches: `docker-compose.yml` (edit), possibly `workflows/.gitkeep` — 1-2
  files, no new deps -> LOW complexity (Engineer -> Executor -> Validator,
  no Planner stage).
