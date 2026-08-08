# EXEC — 2026-08-08-mount-workflows-volume

## v1
Changed files:
- docker-compose.yml (edit)
- workflows/.gitkeep (new)

Added a bind mount `./workflows:/home/node/.n8n/workflows` alongside the
existing `n8n_data:/home/node/.n8n` named volume (R1, R2). No secret values
introduced (R3). Created `workflows/` at repo root with a `.gitkeep`
placeholder so the bind mount source exists and the directory is tracked
even when empty (A4).

Verification: `docker` CLI is not available in this sandbox, so
`docker compose config` could not be run directly. Verified the file parses
as valid YAML via `python3 -c "import yaml; yaml.safe_load(open('docker-compose.yml'))"`
(A2 — structural validation; full compose-schema validation should be
re-run with `docker compose config` on a host with Docker installed before
first use).

STATE: stage=EXECUTED, next_actor=Validator, exec_version=1
