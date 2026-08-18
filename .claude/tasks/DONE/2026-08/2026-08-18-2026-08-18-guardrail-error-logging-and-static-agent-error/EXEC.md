# EXEC — 2026-08-18-2026-08-18-guardrail-error-logging-and-static-agent-error
owner: Executor

## v1 — HALTED at PLAN.md's open verification point

### Applied to Cloud `bLflLYfGzORWkjJV` (published, activeVersionId ed4edf60)
- PLAN step 1: `Guardrails - Screen User Input` now carries
  `onError: "continueErrorOutput"` and `retryOnFail: true`.
- PLAN step 2: added `Execute Workflow - Log Guardrail Error`
  (`n8n-nodes-base.executeWorkflow` v1.3, `onError: continueRegularOutput`),
  parameters mirroring `Execute Workflow - Log Agent Error` with
  `context: "Guardrails - Screen User Input"`.
- PLAN step 3: added `Set - Format Guardrail Error` (`n8n-nodes-base.set`
  v3.5), one `output` assignment holding the R3 literal as a plain string.
- Connections: `Guardrails - Screen User Input` output index 2 ->
  `Execute Workflow - Log Guardrail Error` -> `Set - Format Guardrail Error`.
- PLAN step 4: `Set - Format Agent Error` value replaced with the same plain
  static string. The node was removed and re-added (same id `1d0bb947-...`,
  same position, connection restored) because `update_workflow` exposes no
  operation for editing `notes`, and its notes still described building a
  message from the underlying error.

### Verification result — the plan's assumption does not hold
PLAN.md v1 assumed the guardrail node throws on classifier failure and that
`onError: "continueErrorOutput"` would surface that failure on a third `main`
output. Execution 160 (`chatInput: "100 USD -> EURO"`, the exact message from
the reported incident) disproves the second half:

```
Guardrails - Screen User Input
  executionStatus: "success"
  data.main: [ [], [ <item> ], [] ]        <- index 0 Pass, 1 Fail, 2 error
  item.json.checks: [
    { name: "jailbreak",         triggered: true, executionFailed: true,
      exception: { description: "Guardrail validation failed: Bad request - please check your parameters" } },
    { name: "topicalAlignment",  triggered: true, executionFailed: true,
      exception: { description: "Guardrail validation failed: Bad request - please check your parameters" } }
  ]
lastNodeExecuted: "Set - Format Guardrail Refusal"
```

Findings, in order of importance:

1. **The error output exists at index 2 and is empty.** The connection is
   wired correctly — index 2 is confirmed to be the error output, so that part
   of the plan was right — but nothing ever arrives on it.
2. **The guardrail node catches its own classifier exceptions.** It does not
   throw. Each failed check is reported *inside* the normal result object as
   `triggered: true, executionFailed: true`, and the item is emitted on the
   **Fail** output (index 1). The node fails closed, which is the safe
   direction, but it means `onError` never fires and the entire error branch
   built by this task is unreachable dead code.
3. **The user-visible symptom is therefore not what the incident suggested.**
   A broken classifier does not produce a raw n8n error in chat on the current
   published version — it produces
   `"Invalid request. I can only help with currency conversion."` from
   `Set - Format Guardrail Refusal`. A legitimate conversion question is
   answered with a refusal that blames the user's input, when the real cause
   is an infrastructure failure. That is arguably worse than the reported
   symptom: it is silent, indistinguishable from a genuine refusal, and still
   writes nothing to `error_log`.
4. R1 and R2 are **not met**. R3 (static message, no interpolation, on both
   `Set - Format Agent Error` and `Set - Format Guardrail Error`) **is** met
   and is independently verifiable from the published graph.

Per PLAN.md's "Open verification point", this is an `architecture` issue and
the Executor stops here rather than improvising a distinguisher.

### Notes for the Planner
- The signal the redesign needs is already in the item on the Fail output:
  `checks[].executionFailed` is `true` for an infrastructure failure and
  absent/false for a genuine policy trip. An `IF`/`Switch` on
  `$json.checks.some(c => c.executionFailed)` placed on the Fail branch would
  separate "guardrail rejected the input" from "guardrail could not run",
  routing the latter to the logger + `Set - Format Guardrail Error` and the
  former to the existing `Set - Format Guardrail Refusal`.
- Whether the error output on the guardrail node should then be kept at all is
  a Planner call. It is currently harmless but unreachable; leaving unreachable
  wiring in the graph is the kind of thing the next reader trips over.
- `retryOnFail: true` on the guardrail node is worth keeping regardless — a
  transient rate limit currently turns into a bogus refusal on the first try.

### State left on Cloud
The instance is **published with the changes above**. Nothing is broken: the
static messages (R3) are live and correct, and the new error branch is inert
rather than harmful. No forced-failure teardown is pending — the failure
reproduced on its own, because the OpenAI credential is genuinely exhausted
("Bad request - please check your parameters" on every classifier call), so no
model id was temporarily broken and nothing needs restoring.

`workflows/ai-chat-currency-agent.json` has **not** been re-exported yet: the
graph is expected to change again in the redesign, and exporting an
intermediate shape would put a node layout in the repo that never ran
correctly. Export happens once the Planner's v2 is executed.

### Pre-existing, untouched
`update_workflow` reports two validation warnings on every call:
`OpenAI Chat Model - GPT` and `OpenAI Chat Model - Guardrails` both carry an
empty `builtInTools: {}` which is only permitted with
`responsesApiEnabled: true`. Pre-existing, unrelated to this task, and not
changed here. The empty object has no runtime effect; the clean fix is to drop
the field rather than enable the Responses API. Worth its own task.

## Open issue for the Planner
- id: EXEC-1
  type: architecture
  severity: blocking
  ref: "PLAN.md v1 open verification point resolved negatively: the guardrail
    node catches classifier exceptions internally and emits them on the Fail
    output (index 1) as `checks[].executionFailed: true`, so `onError` never
    fires and the index-2 error branch is unreachable. R1/R2 need a design that
    discriminates on `executionFailed` within the Fail branch. R3 is met and
    needs no rework."

## v2 — PLAN.md v2 executed, R1/R2/R3 verified
exec_version: 2

### Blocked once, then applied
The first `update_workflow` attempt returned `Cannot modify workflow while it is
being edited by a user in the editor` — the Engineer had the workflow open in
the n8n editor with an unpublished draft (`versionId bfc25866`) ahead of the
published version. The call is atomic, so nothing partial landed. Re-ran after
the editor was closed: 6 operations applied, then published
(`activeVersionId 9a77889c`).

### Changes on Cloud `bLflLYfGzORWkjJV`
- Added `Execute Workflow - Log Guardrail Outcome`
  (`n8n-nodes-base.executeWorkflow` v1.3, `onError: continueRegularOutput`) on
  the guardrail Fail branch.
- Rewired `Guardrails - Screen User Input` output index 1: was -> `Set - Format
  Guardrail Refusal`, now -> `Execute Workflow - Log Guardrail Outcome` ->
  `Set - Format Guardrail Refusal`.
- Moved `Set - Format Guardrail Refusal` to `[592, 816]` to make room.
- v1's index-2 branch left untouched, per PLAN v2 step 2.

### Verification — execution 163
`chatInput: "100 USD -> EURO"`, execution status `success`.

`Execute Workflow - Log Guardrail Outcome` ran (source: `Guardrails - Screen
User Input` output **1**, confirming the Fail path is the one a failed
classifier takes) and its sub-execution 164 against `w5dvcvpZ5b9AVTLC` returned
the inserted row:

```json
{ "source_workflow": "AI Chat Currency Agent",
  "context": "Guardrails - Screen User Input",
  "message": "jailbreak (classifier failed: Guardrail validation failed: Bad request - please check your parameters); topicalAlignment (classifier failed: Guardrail validation failed: Bad request - please check your parameters)",
  "id": 1, "createdAt": "2026-08-18T06:53:56.546Z" }
```

`id: 1` — this is the first row ever written to `error_log`, which is the
reported symptom (`Total 0`) resolved directly. A1 met. The `message`
expression evaluated correctly against the real item shape, including the
`executionFailed` -> `(classifier failed: ...)` mapping.

`Set - Format Guardrail Refusal` then ran and produced
`output: "Invalid request. I can only help with currency conversion."` — a
fixed string, no raw error text, no HTML. A2 met under the amended wording.

`Set - Format Agent Error` and `Set - Format Guardrail Error` both hold plain
string values with no `$json.error` reference. A3 met by static read of the
published graph.

### Repository JSON (R4/A4) — synced
`workflows/ai-chat-currency-agent.json` rebuilt from the published Cloud graph
(22 nodes), with two deliberate deviations, both pre-existing conventions of
this file rather than choices made here:
- Top-level `"active": true` is kept (Cloud reports it, and the import tooling
  needs it — CLI import does not honor the field, so `activate_workflow.sh`
  reads it).
- The `credentials` blocks on `OpenAI Chat Model - GPT` and `OpenAI Chat Model
  - Guardrails` are taken from the previous repo file
  (`openAiApi: {id: llmOpenAiApiCred}`), **not** from Cloud. Cloud carries no
  credential on either node at all — it runs on n8n's built-in free AI credits,
  which is exactly what is now exhausted. Exporting Cloud verbatim would strip
  the credential reference the Docker stand needs. Recorded here because it
  means the two instances genuinely differ on this point, and a future
  mechanical export will re-introduce the discrepancy unless it preserves these
  two blocks.
- `issues` and `webhookId` runtime fields stripped.

Secret scan (A5): no literal key material; credential name/id references only.

### Docs (R7/A6)
`docs/workflows/chat-agent/README.md`: diagram updated to three guardrail
branches; new "When the classifier itself fails" section explaining the
fail-closed behavior, the accepted consequence that a valid question can be
answered with a refusal, and that `error_log` now holds every guardrail outcome
rather than only failures; the agent-failure section corrected — it claimed the
message carried "no technical detail" while the node interpolated
`$json.error.message`, which is validation issue V-2 on task
2026-08-18-openai-rate-limit-error-handling and is now true rather than
aspirational.

### Known gaps — recorded, not worked around
- **The Pass path is untested.** Every OpenAI call currently fails, so this task
  could not verify that a valid question still reaches the agent and the
  `convert_currency` tool. The rewiring touched only the Fail branch, and the
  Pass connection is unchanged in the exported graph, but that is an argument,
  not a test. The Engineer re-runs a normal conversion once a working OpenAI
  credential is in place.
- **Docker instance not synced.** Out of scope by TASK constraint; tracked as
  V-1 on task 2026-08-18-openai-rate-limit-error-handling.
- **Pre-existing validation warnings unchanged.** `builtInTools: {}` on both
  OpenAI model nodes is only permitted with `responsesApiEnabled: true`. No
  runtime effect; the clean fix is to drop the field. Deserves its own task.

## v3 — PLAN.md v3 executed
exec_version: 3

### Blocked once again, then applied
Second occurrence of `Cannot modify workflow while it is being edited by a user
in the editor`. Atomic call, nothing partial landed. Re-ran after the Engineer
closed the editor: 4 operations applied, published
(`activeVersionId d322a004`).

### Changes on Cloud `bLflLYfGzORWkjJV`
All four `Execute Workflow - Log ...` nodes had their `message` expression
replaced via `setNodeParameter` on `/workflowInputs/value/message`:
- `Log Guardrail Outcome` — existing checks summary, wrapped so the
  `[execution <id>]` suffix applies to the fallback string too, not only to the
  populated case.
- `Log Guardrail Error` and `Log Agent Error` — gained
  `($json.error && $json.error.description ? ' -- ' + $json.error.description : '')`
  ahead of the suffix.
- `Log Tool Error` — suffix only.

### Verification — execution 171
Row written by the sub-execution:

```
message: "jailbreak (classifier failed: Guardrail validation failed: Bad request
          - please check your parameters); topicalAlignment (classifier failed:
          Guardrail validation failed: Bad request - please check your
          parameters) [execution 171]"
```

`$execution.id` resolves correctly and matches the parent execution, not the
`w5dvcvpZ5b9AVTLC` sub-execution (172) — worth stating explicitly, since the
expression is evaluated in the caller and the id a reader needs is the caller's.
The pointer is therefore usable: opening execution 171 shows the
`OpenAI Chat Model - Guardrails` sub-node error with
`description: "It looks like you've used all your free n8n AI credits..."`.

### Unverified, as PLAN v3 required be stated
The `$json.error.description` clause on `Log Agent Error` and
`Log Guardrail Error` is **not tested**. Neither path can be reached while the
quota is exhausted: the guardrail fails first and the agent never runs, and the
guardrail's own index-2 branch requires a thrown error the node does not throw.
The clause is guarded by a presence check, so if `description` is absent on an
n8n error item the expression yields exactly the v2 string plus the suffix —
degradation, not breakage. It should be confirmed once a working OpenAI
credential exists.

### Repository JSON and docs
`workflows/ai-chat-currency-agent.json`: the four `message` values patched in
place to the exact strings sent to Cloud (targeted edit rather than a re-export,
so the credential-block divergence recorded in v2 is not disturbed). JSON parses.

`docs/workflows/chat-agent/README.md`: new subsection "Why the logged cause is
vague, and what to do about it" — records the `message`/`description` split, the
guardrail node discarding the latter, the `[execution <id>]` convention across
all four loggers, and the fact that the vagueness is partly an artefact of n8n's
AI-credits proxy rather than of this workflow.

## v4 — V-1 resolved
exec_version: 4

Re-exported `workflows/ai-chat-currency-agent.json` from the published Cloud
graph instead of patching it in place, which is what let the file drift in the
first place. Both divergences the Validator found are gone:
- 17 node positions now match Cloud, including the Engineer's canvas
  rearrangement.
- `Execute Workflow - Log Guardrail Outcome` no longer carries `mode`/`source`
  in the file, matching Cloud, which strips them as defaults.

Re-verified after writing: zero residual node-field differences against Cloud
(excluding `credentials`), `connections` identical, JSON parses, secret scan
clean. The two `credentials` blocks are preserved from the previous file per the
deviation recorded in v2 — Cloud carries none on either OpenAI node, and
exporting that verbatim would strip the reference the Docker stand needs.

Lesson worth carrying: a targeted patch of the repository file is only safe when
the instance has not moved. It had — the Engineer was editing the canvas in the
same window during which `update_workflow` was blocked twice. Re-export is the
default; patching in place is the exception and needs a reason.
