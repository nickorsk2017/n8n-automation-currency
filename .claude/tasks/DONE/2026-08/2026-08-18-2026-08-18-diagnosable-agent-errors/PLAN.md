# PLAN — 2026-08-18-diagnosable-agent-errors
owner: Planner
plan_version: 1

## The mistake being corrected
Both error-branch loggers were written as
`$json.error && $json.error.message ? $json.error.message : '<fallback>'`.
That shape encodes a guess about the item, and when the guess is wrong the
expression throws away the only copy of the information. The fallback string is
worse than useless: it looks like a recorded error while carrying none of it,
which is why three identical rows told us nothing.

The design rule this violates: a diagnostic path must degrade toward *more*
raw data, never toward less. A logger that cannot parse its input should
preserve it verbatim and let a human parse it.

## Design

1. `Execute Workflow - Log Agent Error` and
   `Execute Workflow - Log Guardrail Error` — replace the `message` expression
   with one that tries the known fields, and serialises the item when none are
   present:

   ```
   ={{ ($json.error && ($json.error.message || $json.error.description)
        ? [$json.error.message, $json.error.description].filter(Boolean).join(' -- ')
        : '<context> failed; raw item: ' + JSON.stringify($json).slice(0, 500))
       + ' [execution ' + $execution.id + ']' }}
   ```

   `<context>` is `AI Agent` or `Guardrail screening` respectively. Notes on the
   shape:
   - `.message` and `.description` are joined rather than chosen between, so a
     provider error that populates both is not truncated to one. This is the
     v3 behaviour of the previous task, retained.
   - The 500-character slice bounds the row. The `error_log.message` column is
     a string with no stated limit, but an unbounded `JSON.stringify` of an
     agent item can be very large, and a logger that can fail on size is a
     logger that loses the error it was recording.
   - `$execution.id` moves outside the conditional so it is present on every
     row including the fallback. In the current expression the suffix is
     already outside; keeping it there is deliberate, not incidental.

2. Remove `builtInTools` from `OpenAI Chat Model - GPT` and
   `OpenAI Chat Model - Guardrails` via `updateNodeParameters` with
   `replace: true`, passing the remaining parameters (`model`, `options`)
   explicitly. `setNodeParameter` cannot delete a key, so a replace is required.

## What this task does and does not claim
It does not diagnose the agent failure. It removes an invalid field that is a
plausible cause, and it makes the next occurrence self-describing. Those are
two independent improvements, and conflating them would be a mistake: if the
agent still fails after R3, that is not a failed task — it is the improved
logging doing its job.

## Verification
- A1 is checkable by an actor: `update_workflow` returns its validation
  warnings in the response, so a clean response is direct evidence.
- A2 is not checkable by any actor. Cloud has no quota, Docker is unreachable.
  Executor states this rather than substituting an execution-data check, per the
  precedent set by 2026-08-18-chat-response-mode-lastnode.
- The expression's own syntax is checkable before it ever runs: it must survive
  `validate_workflow`, and the fallback branch can be reasoned about from the
  known item shape (an item with no `error` key at all still serialises).

## Rollout
Cloud -> re-export -> docs only if the terminal-node contract changes (it does
not; this touches logger internals, which the docs do not enumerate) -> Docker
via `2026-08-18-sync-chat-agent-to-docker`.
