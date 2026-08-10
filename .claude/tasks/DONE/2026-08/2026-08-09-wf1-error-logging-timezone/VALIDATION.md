# VALIDATION — 2026-08-09-wf1-error-logging-timezone

## v1
- **A1 PASS.** No `n8n-nodes-base.noOp` node remains in the workflow. All three
  failure branches (HTTP Request output 1, IF - Response OK false, IF - Rows
  Valid false) converge on `Code - Build Error Record`, whose jsCode emits all
  four required fields. Verified structurally in the exported file and observed
  live in execution 40, where the record carried real values in every field
  rather than nulls.
- **A2 PASS.** The branch terminates in `Stop and Error - Fail Loader Run`.
  Execution 40 returned `status: error`, so this is confirmed behaviourally and
  not merely by node type.
- **A3 PASS.** `Data Table - Upsert Rate Row` has exactly one inbound
  connection, from `Split Out - Rows To Items`. Neither error-path node reaches
  it. In execution 40 the Data Table node is absent from runData entirely — it
  never ran, which is stronger evidence than the static check.
- **A4 PASS.** `settings.timezone = "UTC"` in the exported file and on the live
  workflow, plus `GENERIC_TIMEZONE=UTC` and `TZ=UTC` in docker-compose.yml. The
  Schedule Trigger note now states 06:00 UTC as fact; the previous "honored as
  UTC only if..." caveat is gone. The workflow-level setting is what makes this
  hold on the Cloud stand too, per the PLAN v2 amendment.
- **A5 PASS with one documented exception.** Live and exported node sets,
  connections, parameters and workflow settings agree. The exception is the
  `Schedule Trigger - Daily FX Pull` note text: the MCP update interface has no
  operation for editing an existing node's notes, so the live node retains the
  superseded caveat. Non-blocking — notes are documentation, the exported file
  is the review artifact per root CLAUDE.md, and the next editor-side re-export
  will reconcile it.

### Checks beyond acceptance
- No secret-like literals in the exported JSON (credential references only).
- Execution 39 confirms the happy path still upserts rather than appends
  (`createdAt` preserved, `updatedAt` refreshed across 33 rows), so the error
  handling change did not regress the idempotency guarantee from the earlier
  loader task.
- The Executor's finding that classification is shape-based rather than
  branch-based is not a defect: execution 40 arrived via the IF false branch
  and was still labelled HTTP_FETCH correctly. Recorded in EXEC.md so a future
  refactor does not silently reintroduce branch-based labelling.

### Notes for downstream tasks (not blocking, not open issues on this task)
- Workflow id drift between the exported file (`OgOk0TrsiV3xsNv9`) and the live
  instance (`iBdFv2bTfVR7chbE`) remains. TASK.md scoped it out explicitly and it
  belongs to the export/sync task; flagging here so it is not lost.
- A persisted `loader_errors` table remains the natural next step if an audit
  trail across runs is ever required; deliberately out of scope.

No blocking issues.

result: PASS
validation_version: 1
STATE: stage=VALIDATED, status=PASS, next_actor=Engineer (close via runner.py done)
