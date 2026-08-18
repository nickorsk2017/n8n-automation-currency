# PLAN — 2026-08-18-2026-08-18-guardrail-error-logging-and-static-agent-error
owner: Planner

## v1

### Root cause (R1/R2)
`Guardrails - Screen User Input` is a `@n8n/n8n-nodes-langchain.guardrails` v2
node in `classify` mode. Its classifier model, `OpenAI Chat Model - Guardrails`,
is an `ai_languageModel` sub-node and therefore has no output branch of its own:
when the OpenAI call fails, the error surfaces on the guardrail node that called
it. The guardrail node currently declares neither `onError` nor `retryOnFail`,
so the error is thrown, the execution aborts, and n8n's chat layer falls back to
rendering the raw exception text — which is why the credits message arrived in
the chat window with its `<a href=...>` markup intact.

Because the guardrail sits directly after `Chat Trigger - Currency Agent Entry`
and before `AI Agent - Currency Assistant`, none of the existing handling on the
agent branch is reachable on this path. This is the same failure shape already
solved for the agent (`onError: continueErrorOutput` -> logger -> formatter);
the fix is to give the guardrail the same treatment, not to invent a new
mechanism.

### Design

1. `Guardrails - Screen User Input`: add generic node properties
   `onError: "continueErrorOutput"` and `retryOnFail: true`. `retryOnFail`
   matches what `AI Agent - Currency Assistant` already carries and is
   warranted by the identical failure class — a transient rate limit should be
   retried before it becomes a user-visible error. The node's own guardrail
   parameters are not touched.

2. New node `Execute Workflow - Log Guardrail Error`
   (`n8n-nodes-base.executeWorkflow`, typeVersion 1.3), fed from the guardrail
   node's error output. Parameters mirror the existing
   `Execute Workflow - Log Agent Error` exactly, so both callers present the
   same shape to the shared logger:
   - `mode: "once"`, `source: "database"`,
     `workflowId: {__rl: true, mode: "id", value: "w5dvcvpZ5b9AVTLC"}`
     (the resource locator has no by-name mode; the fixed id is the portable
     equivalent, per root CLAUDE.md).
   - `workflowInputs.value`: `source_workflow: "AI Chat Currency Agent"`,
     `context: "Guardrails - Screen User Input"`,
     `message: "={{ $json.error && $json.error.message ? $json.error.message :
     'Guardrail screening failed (no error message available)' }}"`.
     `context` naming the guardrail node is what A1 checks for, and is what
     distinguishes this row from an agent-branch row.
   - `onError: "continueRegularOutput"`, same reasoning as on the agent branch:
     a logging failure must not replace or mask the error already being
     reported to the user.
   - The `schema` array is copied from `Execute Workflow - Log Agent Error`;
     the sub-workflow's input contract (`source_workflow`, `context`,
     `message`, no timestamp — `error_log.createdAt` is the timestamp) is
     unchanged and no new column is needed.

3. New node `Set - Format Guardrail Error` (`n8n-nodes-base.set`,
   typeVersion 3.5, `mode: "manual"`), after
   `Execute Workflow - Log Guardrail Error`. One assignment,
   `name: "output"`, `type: "string"`, holding the R3 literal with **no**
   leading `=` — a plain string value, not an expression, so no error text can
   leak into it by construction. `output` is the field the agent's successful
   runs, `Set - Format Agent Error` and `Set - Format Guardrail Refusal` all
   use, so it reaches the chat user through the same path.

4. `Set - Format Agent Error`: replace its current expression value with the
   same plain static string, again with no leading `=` (R3/A3). Its `notes` is
   updated to say the raw error is deliberately not surfaced because
   `Execute Workflow - Log Agent Error` has already recorded it.

5. Positions: place the two new nodes below the guardrail node and clear of the
   existing agent error branch (`Execute Workflow - Log Agent Error` at
   `[1104, 320]`, `Set - Format Agent Error` at `[480, 820]`). Suggested
   `[720, -120]` and `[960, -120]` — above the guardrail's Pass row, mirroring
   how `Set - Format Guardrail Refusal` sits at `[720, 140]`. Exact coordinates
   are cosmetic; non-overlap is not.

### Rejected alternative
Converging both error branches on a single shared formatter node (renamed to
something like `Set - Format System Error`) would keep the user-facing string in
one place instead of two. Rejected: the workflow already establishes one
terminal `Set` node per branch, each holding its own fixed text
(`Set - Format Guardrail Refusal` alongside `Set - Format Agent Error`), and
convergence would require renaming a node that TASK R3/A3 identifies by name.
Two short literals duplicated is a smaller cost than breaking that pattern and
that reference. If a third branch ever needs the same string, revisit.

### Open verification point (Executor must confirm empirically, do not guess)
The guardrail node in `classify` mode already declares two `main` outputs
(index 0 Pass, index 1 Fail). This plan assumes `onError:
"continueErrorOutput"` appends the error output at **index 2**, after the
declared ones. Executor must confirm the actual index from
`get_workflow_details` after applying `onError` and before wiring the
connection — connecting to the wrong index would silently route Fail-classified
user input into the error logger, which is a correctness bug the guardrail is
specifically there to prevent. If n8n does not expose an error output on a
multi-output node at all, that is an `architecture` issue: stop and route back
to the Planner rather than improvising (the fallback direction would be the
workflow-level `errorWorkflow` setting, which satisfies R1 but cannot satisfy
R2, so it is a design change, not an implementation detail).

### Constraint check — the guardrail must not fail open
TASK constrains that a classifier failure must not become an implicit pass.
The design satisfies this structurally: the error output is a third branch
terminating in `Set - Format Guardrail Error`, with no connection back to
`AI Agent - Currency Assistant`. Executor must not add one, and must not
substitute `onError: "continueRegularOutput"` (which would emit the failed item
on output index 0 — the Pass branch — and send unscreened input straight to the
agent). This is the single most important review point of the task.

### Rollout order (R4)
1. Apply steps 1-4 to Cloud workflow `bLflLYfGzORWkjJV` via `update_workflow`,
   using `get_node_types` / `validate_workflow` before and after, then
   `publish_workflow` — draft edits are not served to the live chat until
   published, as the previous task established.
2. Force a guardrail failure and verify A1/A2 (see below).
3. Fetch the final graph with `get_workflow_details` and sync
   `workflows/ai-chat-currency-agent.json` to match it exactly — credential
   references only, never literal keys (R5/A5).
4. Update `docs/workflows/chat-agent/README.md` (R7/A6).

### Verification method (A1/A2)
Forcing the failure: temporarily point `OpenAI Chat Model - Guardrails` at a
non-existent model id, publish, run one chat execution via `execute_workflow`,
then **restore the real model id, re-publish, and re-export**. The plan is not
complete with the instance left in the forced-failure state; Executor records
both the break and the restore in EXEC.md.

What to assert:
- `search_data_tables` / row read on `error_log` shows exactly one new row with
  `context == "Guardrails - Screen User Input"` (A1). Record the row count
  before the forced run so "exactly one new" is measurable rather than
  asserted.
- `get_execution` shows execution status `success`, the guardrail node's data
  carrying the item on the error output rather than index 0, and the branch
  terminating at `Set - Format Guardrail Error` with `output` holding the R3
  literal and no HTML (A2).
- `Set - Format Agent Error`'s stored value contains no `$json.error` (A3) —
  a static read of the published graph, no execution needed.

The previous task verified the equivalent agent-branch behavior through
`execute_workflow`/`get_execution` rather than the hosted chat widget, and that
evidence was accepted. Same standard applies here; if the Engineer can spot-check
the real chat URL afterwards, that is a bonus, not a gate.

### Files/resources touched
- Live Cloud workflow `bLflLYfGzORWkjJV` (via n8n MCP)
- `workflows/ai-chat-currency-agent.json`
- `docs/workflows/chat-agent/README.md`

### Note for the Engineer (out of scope, not an issue on this task)
`docs/workflows/error-logger/README.md` states that import order between
`ai-chat-currency-agent` and `error-logger` "doesn't matter". That is no longer
true — activation order does matter, which is exactly what task
2026-08-18-2026-08-18-import-all-activation-order fixed. Worth a separate task.

## v2
plan_version: 2
supersedes: v1 design steps 1-3 (step 4, the static `Set - Format Agent Error`
value, is already executed and verified — v2 does not touch it)

### What v1 got wrong
v1 assumed a failing classifier makes the guardrail node throw, so that
`onError: "continueErrorOutput"` would carry the failure to a third `main`
output. EXEC v1 disproved it: the node catches its own classifier exceptions
and emits the item on the **Fail** output (index 1) with
`checks[].executionFailed: true`. The index-2 error output exists and is wired,
but nothing reaches it. v1's error branch is therefore correct code on an
unreachable path.

### What changed in the requirement
TASK R2/A2 were amended by the Engineer: telling a rejection apart from a
failure is out of scope, and recording the failure in `error_log` is the only
binding requirement. That removes the need for the `executionFailed`
discriminator EXEC v1 suggested, and with it the IF/Switch node and the
question of which message each case gets.

### Design
Log on **both** guardrail exits, and change nothing about which message the
user sees.

1. New node `Execute Workflow - Log Guardrail Outcome`
   (`n8n-nodes-base.executeWorkflow` v1.3,
   `onError: "continueRegularOutput"`), inserted on the Fail branch between
   `Guardrails - Screen User Input` output index 1 and the existing
   `Set - Format Guardrail Refusal`. Same shape as the other two logger
   callers:
   - `source_workflow: "AI Chat Currency Agent"`
   - `context: "Guardrails - Screen User Input"`
   - `message`: an expression summarising the `checks` array, e.g.
     `={{ ($json.checks || []).filter(c => c.triggered).map(c => c.name + (c.executionFailed ? ' (classifier failed: ' + ((c.exception && c.exception.description) || 'no detail') + ')' : ' (input rejected)')).join('; ') || 'Guardrail returned no triggered checks' }}`
     Executor confirms the exact expression evaluates against the real item
     shape recorded in EXEC v1 before relying on it.

   The branch does not discriminate, but the `message` it writes still
   carries `executionFailed` and the exception text, so the cause remains
   recoverable **from the log** without any branching in the graph. This is
   the point of the design: move the distinction out of the workflow and into
   the recorded row, where reading it costs nothing and getting it wrong
   breaks nothing.

2. Keep v1's index-2 branch (`Execute Workflow - Log Guardrail Error` ->
   `Set - Format Guardrail Error`) exactly as built. It is unreachable for a
   classifier failure, but the reported incident showed a raw n8n error string
   reaching the chat widget, which means *some* path through this node can
   still throw — a node-level failure the node's internal handler does not
   cover. Keeping the branch is a few nodes of insurance against precisely the
   symptom that opened this task, and it costs nothing when idle. `onError:
   "continueErrorOutput"` and `retryOnFail: true` stay on the guardrail node
   for the same reason.

3. No IF/Switch node, no change to `Set - Format Guardrail Refusal`, no change
   to `Set - Format Agent Error` (already done in v1 execution).

### Rejected alternative
Discriminating on `checks.some(c => c.executionFailed)` with an IF node, as
EXEC v1 proposed. It is the technically better answer — a user asking a valid
question would stop being told their input was invalid — but the Engineer
scoped it out. Recording it here so the next reader knows the misleading
refusal is a known, accepted behavior rather than an oversight, and knows
exactly where the signal lives if it is ever picked up.

### Note on `error_log` contents
Every guardrail rejection now writes a row, so the table will hold ordinary
policy refusals ("what's the weather?") alongside genuine failures. That is
the accepted consequence of not discriminating. The `message` text is what
separates them on read: `(input rejected)` versus
`(classifier failed: ...)`.

### Verification (A1/A2)
The OpenAI credential is exhausted, so every classifier call currently fails —
no forced breakage is needed, and none should be introduced.
- Run one chat execution and confirm from `get_execution` that
  `Execute Workflow - Log Guardrail Outcome` ran and its sub-workflow returned
  the inserted row (the `Execute Workflow` node's output is the sub-workflow's
  last node output, i.e. the `error_log` row) — that is A1's evidence without
  needing a row-read tool the MCP does not expose.
- Confirm `lastNodeExecuted` is `Set - Format Guardrail Refusal` and its
  `output` is the fixed refusal string — A2 under the amended wording.
- Confirm `Set - Format Agent Error`'s stored value contains no `$json.error`
  (A3) by reading the published graph.
- **Known gap, to record in EXEC, not to work around:** with the credential
  exhausted, the Pass path cannot be exercised at all, so this task cannot
  regression-test that a valid question still reaches the agent. Executor
  states this plainly; the Engineer re-tests after adding a working OpenAI
  key.

### Then
Re-export to `workflows/ai-chat-currency-agent.json` (R4/A4), check no secrets
(R5/A5), update `docs/workflows/chat-agent/README.md` (R7/A6) — including the
`error_log`-contents consequence above and the fact that a classifier failure
currently surfaces as a refusal.

## v3
plan_version: 3
extends: v2 (no v2 decision is reversed; this adds to what v2 built)

### Trigger
The Engineer read the first `error_log` rows and found the recorded cause
unusable: `"Bad request - please check your parameters"` says nothing about the
actual condition, which is an exhausted n8n AI-credits quota. Investigation of
execution 163 established where the useful text lives and why the row does not
have it.

### The finding, precisely
The sub-node `OpenAI Chat Model - Guardrails` fails with a `NodeApiError`
carrying two distinct fields:

```
message:     "Bad request - please check your parameters"          <- generic wrapper
description: "It looks like you've used all your free n8n AI credits. ..."   <- the cause
```

The guardrail node, when packing that failure into `checks[].exception`, keeps
only `message` and discards `description`. By the time the item reaches the Fail
branch the cause no longer exists in the data, so no expression on that branch
can recover it. The text the Engineer previously saw in chat came from a
different mechanism entirely — n8n serialising the thrown execution error
itself, which only happens when the execution fails, which v2 deliberately
stopped.

### Decision
Do not restore the failure. Record a pointer to where the full error does
survive: the execution record. `$execution.id` is available in expressions, and
n8n's Executions view shows the sub-node's `description` in full.

### Scope — this is not guardrail-specific
The Engineer asked whether this applies only to the guardrail logger. It does
not. All four `Execute Workflow - Log ...` callers write a row that a human will
later read out of context, and every one of them benefits from naming its
execution. Applying it to one and not the others would make `error_log` a table
where some rows are traceable and some are not, for no reason a reader could
infer.

Beyond the pointer, the four callers are **not** equally impoverished, and v3
treats them differently on purpose:

- `Execute Workflow - Log Agent Error` and `Execute Workflow - Log Guardrail
  Error` receive their item from a genuine n8n **error output**
  (`onError: continueErrorOutput`). That item carries the serialised error
  object, which is not passed through the guardrail node's lossy packing — so
  `$json.error.description` is very likely present and is exactly the field
  that was missing. Both expressions gain it, appended when non-empty.
- `Execute Workflow - Log Guardrail Outcome` cannot be improved this way, for
  the reason established above. Pointer only.
- `Execute Workflow - Log Tool Error` receives a structured validation result
  (`error_code` / `message`), not an error object. Nothing to add beyond the
  pointer.

### Change
Append ` [execution {{ $execution.id }}]` to the `message` expression of all
four loggers, and add the `description` clause to the two error-output ones.
Target shapes:

- Agent / Guardrail Error:
  `={{ ($json.error && $json.error.message ? $json.error.message : '<fallback>') + ($json.error && $json.error.description ? ' -- ' + $json.error.description : '') + ' [execution ' + $execution.id + ']' }}`
- Guardrail Outcome: existing expression + `+ ' [execution ' + $execution.id + ']'`
- Tool Error: `={{ $json.message + ' [execution ' + $execution.id + ']' }}`

### Empirical check for the Executor
Whether `$json.error.description` is actually populated on an n8n error output
is an assumption, not a verified fact — the agent branch cannot be exercised
while the quota is exhausted, since the guardrail fails first and the agent
never runs. The expressions are written defensively (the clause is skipped when
the field is absent), so a wrong assumption degrades to v2 behaviour rather than
breaking the row. Executor states plainly in EXEC that this clause is unverified
rather than implying it was tested.

`$execution.id` itself must be verified — it is the whole point of the change
and is exercised by the guardrail path on every run.

### Docs
`docs/workflows/chat-agent/README.md`: the "When the classifier itself fails"
section must say that the recorded cause is the generic wrapper, that the real
one is in the linked execution, and why — otherwise the next reader repeats this
investigation from scratch.
