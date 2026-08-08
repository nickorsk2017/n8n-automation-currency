# EXEC — 2026-08-08-makefile-n8n

## v1
Changed files:
- Makefile (new)
- README.md (edit, Setup section)

Makefile: `help` (default, self-documenting via `##` comments + grep/awk),
`up` (`docker compose up -d`), `down` (`docker compose down`), `restart`
(`docker compose restart`), `logs` (`docker compose logs -f n8n`), `ps`
(`docker compose ps`) — per plan table (P.R1). No secret referenced (P.R2).

README: replaced the old generic "n8n instance (Docker)" bullet in Setup
with one naming `docker-compose.yml` + the Makefile targets and the local
URL (P.R3), scoped to that single bullet — no other Setup content touched
(P.R4).

STATE: stage=EXECUTED, next_actor=Validator, exec_version=1
