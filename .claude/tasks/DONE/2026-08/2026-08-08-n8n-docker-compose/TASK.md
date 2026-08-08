# TASK — 2026-08-08-n8n-docker-compose
owner: Engineer
immutable: true

## Context
Engineer currently starts n8n locally with an ad-hoc `docker run` command. That is
not reproducible or checked in. Engineer wants a permanent, committed
`docker-compose.yml` so `docker compose up` reliably brings up the same n8n
instance for anyone working in this repo.

## Requirements
- R1: Add `docker-compose.yml` at repo root defining a single `n8n` service using
  the official `docker.n8n.io/n8nio/n8n` image.
- R2: Service exposes port 5678 (host 5678 -> container 5678).
- R3: Service loads environment variables from the existing root `.env` file
  (`env_file: .env`) rather than inlining any secret — consistent with the
  root `CLAUDE.md` rule that secrets never live in workflow JSON or other
  tracked files.
- R4: Persist n8n's data directory (`/home/node/.n8n`) via a named Docker
  volume so workflows/credentials survive container restarts.
- R5: Container restarts automatically (`restart: unless-stopped`) so it
  survives host reboots during development.
- R6: Do not write any literal secret value into `docker-compose.yml`.

## Acceptance
- A1: `docker-compose.yml` exists at repo root, references `.env` via
  `env_file`, maps port 5678, and declares a named volume for
  `/home/node/.n8n`.
- A2: `docker compose config` (or equivalent) parses the file without error.
- A3: No secret value appears literally in `docker-compose.yml`.
- A4: `.gitignore` still ignores `.env`/`.env.*` (already covered by prior
  task `2026-08-08-gitignore`) — `docker-compose.yml` itself is tracked.

## Constraints
- English only in all persisted content (per root `CLAUDE.md` language rule).
- Touches: `docker-compose.yml` (new) — 1 file, no new deps -> LOW complexity
  (Engineer -> Executor -> Validator, no Planner stage).
