# TASK — 2026-08-19-provision-config-on-cloud-stand
owner: Engineer
immutable: true

## Requirements
- R1: The n8n Cloud stand (project 7be3175KDEz3HrYS) holds the `config` data table
  with the same shape the repository provisions — `config_key`, `config_value` —
  and a seeded `base_currency` row.
- R2: The live `Daily Currency Rate Loader` (id iBdFv2bTfVR7chbE) matches
  `workflows/currency-rate-loader.json` as closed in
  2026-08-19-loader-base-currency-from-config: no `Set - Loader Config`, config
  read + gate ahead of the HTTP request, consumers repointed.
- R3: No repository file changes. The exported JSON is already the intended state;
  this task moves the stand to it, not the other way round.

## Acceptance
- A1: `config` exists on the stand with both columns and exactly one
  `base_currency` row whose value is `USD`.
- A2: The live loader's node list, connections and the three base-currency
  consumers are identical in substance to the repository file; no `USD` literal
  and no reference to the deleted node remain live.
- A3: `git status` shows no file modified by this task.

## Constraints
- Export discipline: the instance is being brought to the file, so no re-export
  is due; any divergence found afterwards is a defect of this task, not a new edit.
- The other two workflows on the stand are out of scope and must not be touched.
