# VALIDATION — 2026-08-08-mount-workflows-volume

## v1
Checked EXEC v1 against TASK R1-R4 / A1-A4.

- R1 bind mount ./workflows -> container: OK
  (`./workflows:/home/node/.n8n/workflows` added to n8n service volumes).
- R2 existing n8n_data named volume at /home/node/.n8n retained, not
  removed/replaced: OK.
- R3 no literal secret introduced: OK (grep for secret/KEY patterns clean).
- R4 file parses without error: OK, see A2 note below.
- A1 bind mount present alongside n8n_data volume: OK.
- A2 parse check: docker CLI unavailable in this sandbox; validated via
  `python3 -c "import yaml; yaml.safe_load(...)"` — parses as valid YAML,
  volumes list contains both entries as expected. Not a substitute for
  `docker compose config` (same limitation accepted in prior task
  2026-08-08-n8n-docker-compose); no issue raised. Engineer should re-run
  `docker compose config` locally as a final sanity check before first use.
- A3 no secret value literal in docker-compose.yml: OK.
- A4 workflows/ exists at repo root (workflows/.gitkeep): OK.

open_issues: none

Result: PASS

STATE: stage=VALIDATED, status=PASS, validation_version=1
