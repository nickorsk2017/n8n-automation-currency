# VALIDATION — 2026-08-09-workflow-export-sync

## v1
- **A1 PASS.** `scripts/export_workflow.sh` exists and is executable. Wrong arg
  count exits 1 with a usage line; a run against a stand with no container exits
  1 with "the n8n container is not running. Start it with 'make up' and retry."
  rather than a docker stack trace. Output normalisation to indent-2 JSON with a
  trailing newline is present, as is the single-element-list unwrap. `bash -n`
  clean.
- **A2 PASS.** `make help` lists `export` and `drift` with usage strings in the
  same shape as the pre-existing `import` entry.
- **A3 PASS.** `workflows/1-currency-rate-loader.json` id is `iBdFv2bTfVR7chbE`
  (matching the live instance); `workflows/2-ai-chat-currency-agent.json` is
  unchanged at `bLflLYfGzORWkjJV`. Both parse; node counts 10 and 11, unchanged
  by this task.
- **A4 PASS.** Demonstrated on three real comparisons rather than asserted:
  identical inputs report in sync (exit 0); a copy carrying a changed timezone
  setting, a renamed error node and a changed base currency reports drift (exit
  1) naming each difference; a copy differing only in volatile and cosmetic
  fields reports in sync (exit 0). The third case is the one that matters for
  the check surviving contact with real use.
- **A5 PASS.** Secret scan across `scripts/` and `workflows/` returns only prose
  in comments and node notes asserting that secrets are absent. Neither new
  script reads `.env`.

### Assessment beyond acceptance
The R3 id fix is not cosmetic. Before it, the repo's own documented recovery
path — `make import` — would have created a second loader on the same daily
schedule rather than restoring the existing one, on a stand where the original
had the credential and execution history. The failure would have surfaced as
duplicate writes, not as an import error.

`check_workflow_drift.py` taking two files rather than fetching one itself is
the right seam: the Docker stand is CLI-reachable and the Cloud stand is not, so
binding the comparison to either transport would have made it useless for the
other.

### Known limitation (documented, non-blocking)
End-to-end `make export` / `make drift` through a live container was not
exercised — no Docker stand runs in this session. Guard paths, argument
handling, syntax and the full comparison logic were verified directly; the
unverified remainder is the single `docker compose exec n8n n8n export:workflow`
invocation, whose flags mirror the already-working `import:workflow` call in
`scripts/import_workflow.sh`. Should be confirmed on first use against a running
stand.

No blocking issues.

result: PASS
validation_version: 1
STATE: stage=VALIDATED, status=PASS, next_actor=Engineer (close via runner.py done)
