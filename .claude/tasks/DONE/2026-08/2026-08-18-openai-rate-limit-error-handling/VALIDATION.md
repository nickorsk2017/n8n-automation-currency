# VALIDATION — 2026-08-18-openai-rate-limit-error-handling

## v1
result: FAIL
validation_version: 1

### Requirement conformance
- R1 — MET. `AI Agent - Currency Assistant` carries
  `onError: "continueErrorOutput"` with `retryOnFail` retained, and its output
  index 1 feeds a logging node followed by `Set - Format Agent Error`, which
  writes the user-facing string into the `output` field the agent's successful
  runs use. Executions 155/156 recorded in EXEC.md show a real OpenAI failure
  caught, routed to index 1, logged, and formatted — both halves of R1.
- R2 — MET. Implemented and verified on the live Cloud workflow
  `bLflLYfGzORWkjJV` first, before any repository or Docker change.
- R3 — PARTIAL. Repository JSON is synced (part 1). The Docker instance was
  never brought to the same state (part 2) — see V-1.
- R4 — MET. `workflows/*.json` contains no literal key material; the only
  credential entries are name/id references
  (`openAiApi: {id: llmOpenAiApiCred}`, `httpQueryAuth: {id: fcaHttpQueryAuth}`).
- R5 — MET. Both added nodes follow `<Kind> - <What>` naming and carry `notes`
  citing this task's requirement id.

### Acceptance conformance
- A1 — MET, with the method caveat the Executor flagged. Verified through
  `execute_workflow`/`get_execution` rather than the hosted chat widget. The
  execution record shows the branch terminating at `Set - Format Agent Error`
  with `output` populated and the execution status `success`, which is the
  data the chat response layer reads. Accepted.
- A2 — NOT MET. See V-1.
- A3 — MET for this task's contribution. `workflows/ai-chat-currency-agent.json`
  matches the published Cloud graph on the nodes this task owns
  (`AI Agent - Currency Assistant` generic properties, the error branch, and
  `OpenAI Chat Model - GPT`'s `responsesApiEnabled`). The file has since taken
  further edits from later tasks (shared error logger, guardrails); those are
  outside this task's scope and were not re-judged here.
- A4 — MET. Confirmed by the R4 scan above.
- A5 — NOT MET as written. See V-2.

### Blocking issues
- id: V-1
  type: requirement
  severity: high
  ref: "R3 part 2 / A2 — the Docker instance was never synced or verified.
    `make import FILE=ai-chat-currency-agent.json` and
    `make drift ID=<docker_workflow_id> FILE=ai-chat-currency-agent.json`
    require Docker and N8N_API_URL/N8N_API_KEY for the local container, none
    of which are reachable from the Executor's or the Validator's execution
    environment. Only the Engineer can run these on their own machine and
    report the outcome. Reclassified from the Executor's `architecture` label:
    no design decision is in question, so routing this to the Planner would
    produce nothing — the gap is an access/action one, which is the Engineer's
    column."
- id: V-2
  type: logic
  severity: medium
  ref: "A5 — `docs/workflows/chat-agent/README.md` states that
    `Set - Format Agent Error` produces a message with `(no technical detail)`,
    but the node's expression appends `$json.error.message` in parentheses when
    present, so the raw OpenAI error string does reach the chat user. The
    documentation and the implementation disagree; one of the two is wrong.
    Note for the Engineer: the follow-up task replacing this node's value with
    a fixed static message resolves this in the documentation's favour, at
    which point V-2 can be cleared rather than separately fixed here."

### Routing
Type priority `requirement` > `logic`, so `next_actor: Engineer`.
V-1 needs an Engineer action that no other actor can perform; V-2 is expected
to be resolved by the queued follow-up task on `Set - Format Agent Error`.

## v2
result: PASS
validation_version: 2

### Issue disposition
- V-1 (requirement) — **descoped**, not fixed. The Engineer amended TASK.md to
  move the Docker sync and its acceptance to
  `2026-08-18-sync-chat-agent-to-docker`. This task never verified anything on
  the Docker stand and does not claim to; the successor task owns that. Recorded
  this way rather than as a pass so the audit trail does not read as though a
  Docker verification happened.
- V-2 (logic) — **resolved elsewhere.** The false sentence in
  `docs/workflows/chat-agent/README.md` claiming `Set - Format Agent Error`
  produced a message with "no technical detail" is gone, and the node's value is
  now genuinely a literal. Verified: the string "no technical detail" no longer
  appears in the file, and the section now documents the fixed message and why
  it is a literal rather than an expression. Fixed by task
  2026-08-18-guardrail-error-logging-and-static-agent-error.

### Result
Against the amended scope — Cloud implementation, repository export,
documentation — all requirements and acceptance criteria are met. v1's findings
on R1, R2, R4, R5 and A1, A3, A4 stand unchanged. `open_issues` empty.
