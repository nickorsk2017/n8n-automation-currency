# VALIDATION — 2026-08-19-provision-config-on-cloud-stand

## v1
result: PASS

- A1 PASS — `config` (p0P74SyeGh1NBwyA) holds `config_key`/`config_value` and one
  `base_currency = USD` row; confirmed in execution 187's node output, not only
  in the create response.
- A2 PASS — live node list, connections and the three consumers match the
  repository file in substance; no `Set - Loader Config`, no `USD` literal in
  the graph. Execution 187 ran the whole path green and upserted 33 USD-based
  rows. The published version now equals the verified draft — checked, because
  updating the draft alone would have left the 06:00 schedule on the old graph.
- A3 PASS — no repository file modified by this task.
- Scope PASS — the other two workflows untouched.
- Open issue for the Engineer, non-blocking here: pre-existing repo/instance
  drift recorded in EXEC.md (upsert node resource-locator mode, stale notes,
  positions). Not this task's requirement; worth its own task before the next
  export.
