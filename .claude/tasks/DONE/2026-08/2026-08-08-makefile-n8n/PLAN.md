# PLAN — 2026-08-08-makefile-n8n

## v1

### R1 — Makefile targets
New file at repo root. `.PHONY` targets, `help` first so it is the default
(`make` with no args runs `help`). Each target is a thin wrapper around
`docker compose` against the existing root `docker-compose.yml` (task
`2026-08-08-n8n-docker-compose`, DONE) — no new compose logic, only
orchestration:

| target  | underlying command             | purpose                    |
|---------|---------------------------------|-----------------------------|
| help    | (prints target table)          | default target, self-doc   |
| up      | `docker compose up -d`         | start n8n in background    |
| down    | `docker compose down`          | stop + remove containers   |
| restart | `docker compose restart`       | restart running stack      |
| logs    | `docker compose logs -f n8n`   | follow n8n logs             |
| ps      | `docker compose ps`            | show container status      |

`help` target lists target name + one-line description (satisfies R1/A2)
by parsing `##`-annotated comments after each target — standard
self-documenting-Makefile pattern, keeps target list and description
co-located so they can't drift.

No secret is referenced or echoed anywhere in the file (R2/A3) — `.env` is
read exclusively by `docker compose` itself via the compose file's
`env_file` directive, never by Make.

### R3/R4 — README Setup section
In `README.md`, replace the existing bullet:

> - **n8n instance** — a local, self-hosted n8n instance (Docker) to build,
>   run, and export the workflows.

with a bullet pointing at the compose file and Makefile, naming the
concrete commands (`make up`, `make down`, `make logs`, `make ps`,
`make restart`) and noting `make help` lists all of them. Scope stays
inside the existing "Setup" section — no new top-level heading, no
restatement of other bullets (freecurrencyapi, LLM provider, env vars
bullets untouched).

### Files touched
- `Makefile` (new)
- `README.md` (edit, Setup section only)

Matches TASK's MEDIUM classification (2 files, no new module/schema/infra).

STATE: stage=PLANNED, next_actor=Executor, plan_version=1
