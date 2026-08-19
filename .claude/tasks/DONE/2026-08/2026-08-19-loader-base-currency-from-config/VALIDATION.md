# VALIDATION — 2026-08-19-loader-base-currency-from-config

## v1
result: PASS

### Verified mechanically
- A1 PASS — `Set - Loader Config` absent from nodes, connections and every
  expression/Code body; no `USD` substring anywhere in the loader JSON; graph
  re-derived from `connections`: no dangling reference, no unreachable node,
  trigger -> config read -> gate -> HTTP, downstream untouched. `active: true`
  preserved.
- R2 PASS — the three consumers reference `Data Table - Get Base Currency Config`;
  no consumer holds a currency of its own.
- R5 PASS (static) — `seed_config_if_missing` returns before POSTing whenever a
  non-blank `config_value` exists; `bash -n` clean.
- A6 PASS — new `config-table.md` linked from the loader README and the schema
  page; loader README failure table and runbook renumbered for `CONFIG`; root
  README, `architecture.md`, `Makefile` help and `.env.example` updated; link
  check across all Markdown found no broken relative link; no file still names
  the deleted node. English throughout.
- Scope PASS — `workflows/ai-chat-currency-agent.json` carries only the
  pre-existing working-tree change noted in EXEC.md; this task added nothing to it.
- Harness PASS — `.claude/scripts/ci_check.py` clean.

### Verified by inspection only — runtime not executed
A2-A5 require a running n8n stand, unavailable in this environment (EXEC.md
step 6). Reasoned rather than observed:
- A2 — provisioning creates `config` and seeds `USD`; the get node resolves the
  table by name, so a fresh stand needs no id reconciliation.
- A3 — the value is read per run, not baked at import.
- A4 — seeding is conditional on absence.
- A5 — `alwaysOutputData` guarantees the gate evaluates on a missing row, whose
  false branch reaches the existing error path; the classifier tests the config
  value first, so `CONFIG` cannot be masked by another stage, and the branch
  terminates at `Stop and Error - Fail Loader Run`, which has no path to the
  data table.
Not raised as blocking issues: no artifact change could resolve them, and the
plan's own sequence assigns the run to an operator. Recorded here so the gap is
visible rather than implied — the first `make setup && make import-all` on the
stand is the confirmation.
