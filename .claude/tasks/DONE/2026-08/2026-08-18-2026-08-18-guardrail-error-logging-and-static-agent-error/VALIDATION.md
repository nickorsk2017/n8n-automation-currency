# VALIDATION — 2026-08-18-2026-08-18-guardrail-error-logging-and-static-agent-error

## v1
result: FAIL
validation_version: 1

### Requirement conformance
- R1 — MET. `Execute Workflow - Log Guardrail Outcome` sits on the guardrail
  Fail output and calls `w5dvcvpZ5b9AVTLC`. Executions 163 and 171 each produced
  one row via a sub-execution. The reported symptom (`error_log` empty while the
  quota is exhausted) is resolved: the Engineer's own screenshot shows four rows,
  all `context = "Guardrails - Screen User Input"`.
- R2 (amended) — MET. Execution 171 ends at `Set - Format Guardrail Refusal`
  with `output` holding a fixed string. No provider text, no HTML, execution
  status `success`.
- R3 — MET. All three `Set` nodes hold literal values: none begins with `=`,
  none references `$json.error`. This is verified structurally, not by
  inspecting output, so it holds for every input rather than for the one tested.
- R4 — MET. Cloud was changed and published first (`d322a004`), then the
  repository file was updated. Order is evidenced by the LOG timestamps.
- R5 — MET. No key material in `workflows/*.json`; scan also finds no
  `OPENAI_API_KEY` and no `ai-credits/proxy` URL leaked from execution data into
  the export.
- R6 — MET. All four nodes added or rewritten by this task follow
  `<Kind> - <What>` and carry substantial `notes` citing a TASK requirement id.
- R7 — MET. `docs/workflows/chat-agent/README.md` describes the three guardrail
  branches, the fail-closed behaviour, the `message`/`description` split and the
  `[execution <id>]` convention. All relative links resolve. The false "no
  technical detail" sentence is gone, which also clears V-2 on task
  2026-08-18-openai-rate-limit-error-handling.

### Acceptance conformance
- A1 — MET. One row per failing run, `context` naming the guardrail node.
- A2 — MET under the amended wording.
- A3 — MET. `Set - Format Agent Error` contains no `$json.error`.
- A4 — **NOT MET.** See V-1.
- A5 — MET.
- A6 — MET.

### Blocking issue
- id: V-1
  type: logic
  severity: medium
  ref: "A4 / root CLAUDE.md export discipline — `workflows/ai-chat-currency-agent.json`
    does not match the published Cloud graph. Two divergences, both found by
    diffing the file against `get_workflow_details`:
    (a) 17 of 22 nodes have different `position` values. The Engineer
    rearranged the canvas in the n8n editor during this task — the same editor
    session that blocked `update_workflow` twice — and those moves were never
    exported. This is exactly the case the export-discipline rule names: an
    editor change without a matching export.
    (b) `Execute Workflow - Log Guardrail Outcome` carries `mode: \"once\"` and
    `source: \"database\"` in the repository file and neither on Cloud, which
    stripped them as defaults when the node was created. Behaviour is
    identical; the file still misrepresents the instance.
    Fix is a re-export, with the credential blocks preserved per the deviation
    EXEC v2 documented (Cloud carries no credential on either OpenAI node).
    Classified `logic` rather than `architecture`: no design decision is in
    question, only that the file was patched in place while the instance moved
    underneath it."

### Non-blocking observations
- N1 (test-coverage, medium): the `$json.error.description` clause on
  `Execute Workflow - Log Agent Error` and `Execute Workflow - Log Guardrail
  Error` is unverified, as EXEC v3 states plainly. Accepted rather than raised
  as blocking, because the guard makes absence degrade to the previous string
  and because no path to test it exists while the quota is exhausted. It should
  be confirmed, not assumed, once a working credential exists.
- N2 (test-coverage, medium): the Pass path is untested for the same reason.
  The rewiring touched only output index 1 and the exported `connections` object
  is byte-identical to Cloud's, so the Pass edge is provably unchanged — but
  "unchanged" is not "exercised".
- N3 (evidence quality, low): row counts were verified indirectly, through the
  row each sub-execution returned, because the n8n MCP exposes no data-table
  row-read tool. The returned `id` was `1` on both execution 163 and 171, which
  cannot both be a monotonic table row id given the Engineer's screenshot shows
  ids 1-4. Whatever that field is, it is not evidence of row count, and no
  conclusion here rests on it.
- N4 (hygiene, low): `builtInTools: {}` on both OpenAI model nodes still raises
  a validation warning on every `update_workflow` call. Pre-existing, untouched,
  no runtime effect. Deserves its own task, as EXEC notes.

### Routing
Single issue, type `logic` -> `next_actor: Executor`, `iteration: 1`.

## v2
result: PASS
validation_version: 2

### V-1 re-check
Re-diffed `workflows/ai-chat-currency-agent.json` against the published Cloud
graph: zero node-field differences excluding `credentials`, `connections`
identical, 22/22 node names matching. Both divergences named in v1 are gone —
positions across all 17 nodes and the `mode`/`source` pair on
`Execute Workflow - Log Guardrail Outcome`. The `credentials` exclusion is the
documented deviation, not an oversight: Cloud carries no credential on either
OpenAI node, so a verbatim export would strip the reference the Docker stand
imports against. A4 now met.

No other artifact changed, so v1's findings on R1-R3, R5-R7 and A1-A3, A5-A6
stand unmodified.

### Result
All requirements and acceptance criteria met. `open_issues` empty.
Non-blocking observations N1-N4 from v1 carry forward as recorded facts, not as
gates; N1 and N2 in particular describe verification that is impossible while
the OpenAI quota is exhausted and should be closed by the Engineer re-testing
once a working credential exists.
