# EXEC — 2026-08-08-n8n-docker-compose

## v1
Changed files:
- docker-compose.yml (new)

Single `n8n` service on `docker.n8n.io/n8nio/n8n` (R1). `env_file: .env` loads
secrets at runtime without inlining any value in the compose file (R3, R6).
Port mapping `5678:5678` (R2). Named volume `n8n_data` mounted at
`/home/node/.n8n` for persistence across restarts (R4). `restart:
unless-stopped` (R5). `.env` stays untracked per existing `.gitignore`;
`docker-compose.yml` itself is tracked (A4).

STATE: stage=EXECUTED, next_actor=Validator, exec_version=1
