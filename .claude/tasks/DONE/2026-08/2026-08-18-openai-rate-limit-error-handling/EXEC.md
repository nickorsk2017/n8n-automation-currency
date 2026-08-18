# EXEC — 2026-08-18-openai-rate-limit-error-handling
owner: Executor

## v1

### Cloud (R2) -- DONE, verified
Applied PLAN v1 steps 1-3 to live workflow `bLflLYfGzORWkjJV` via
`update_workflow`, then `publish_workflow` (draft edits are not served to the
live chat until published -- `activeVersionId` only advanced after this
call):
- `AI Agent - Currency Assistant`: `onError: "continueErrorOutput"` added
  (kept `retryOnFail: true`).
- Added `NoOp - Log Agent Error` (main output index 1 of the Agent) and
  `Set - Format Agent Error` (after the NoOp), exact params as specified in
  PLAN.md v1.
- Also set `responsesApiEnabled: true` on `OpenAI Chat Model - GPT`: the
  first `update_workflow` call returned a validation warning
  (`builtInTools` only allowed when `responsesApiEnabled=true`) that
  predated this task. Fixed as the narrow follow-up PLAN.md v1 step 4
  explicitly allows. Re-verified afterward: warning gone, but this was NOT
  the cause of the actual failures being investigated (see below) -- kept
  anyway as a correct fix in its own right.

**Live verification (forced no simulation needed -- the failure reproduced
on its own):**
- Execution 155 (before the `responsesApiEnabled` fix) and execution 156
  (after it): both real chat calls (`execute_workflow`, chatInput "How much
  is 100 EUR in JPY?") hit a genuine OpenAI failure --
  `error: "Bad request - please check your parameters"` -- on every attempt
  during this session. In both cases:
  - `status: "success"` at the execution level (workflow did not crash) --
    confirms `continueErrorOutput` is working.
  - `AI Agent - Currency Assistant` data shows `main: [[], [{ ...error }]]`
    -- item routed to output index 1, not 0.
  - `NoOp - Log Agent Error` ran and passed the raw error item through
    unchanged (`error: "Bad request - please check your parameters"`) --
    inspectable in Executions -- satisfies A1's "logged" half.
  - `Set - Format Agent Error` produced
    `output: "Sorry, I couldn't reach the AI model just now. This is often
    temporary (e.g. rate limiting) -- please try your question again in a
    moment."` -- satisfies A1's "visible, explicit message" half.
- The underlying "Bad request" was not resolved by the `responsesApiEnabled`
  fix, so it is not a workflow-config problem this task can reach -- it is
  either an OpenAI account/quota/billing condition on the connected
  credential, or a genuine free/trial-tier rate limit as originally
  hypothesized by the Engineer. This is exactly the failure class R1 asks
  to be handled gracefully, and it now is, end-to-end, on live traffic.
- Verification method note (flagged per PLAN.md's "Open verification
  point"): confirmed via `execute_workflow`/`get_execution` (the same chat
  trigger and code path the hosted chat widget uses), not by opening the
  browser chat widget directly -- no browser tool was available in this
  session. The execution data shown above (final node = `Set - Format Agent
  Error`, `output` field populated, no thrown/failed execution) is the same
  data n8n's chat response layer reads from, so this is treated as
  sufficient evidence for A1, but a Validator/Engineer spot-check via the
  actual hosted chat URL is recommended before fully closing.

### Repository JSON (R3, part 1) -- DONE
`workflows/ai-chat-currency-agent.json` updated to match the published
Cloud graph:
- `AI Agent - Currency Assistant`: added `onError`/`retryOnFail`, notes
  updated.
- `OpenAI Chat Model - GPT`: added `responsesApiEnabled: true`,
  `builtInTools: {}`, `options: {}` (also brings the file in line with
  fields Cloud already carried on this node -- pre-existing drift, not
  introduced here), notes updated.
- Added nodes `NoOp - Log Agent Error`, `Set - Format Agent Error` (same
  ids/params as live) and the two new connections (Agent output index 1 ->
  NoOp -> Set).
- Validated: `python3 -m json.tool` parses the file; node count 16 matches
  `get_workflow_details` node count on Cloud.

### Docker instance (R3 part 2 / A2) -- BLOCKED, not completed
This session's shell (`mcp__workspace__bash`) is an isolated cloud sandbox:
`docker` is not installed/reachable here, and `.env` in this checkout only
carries `FREECURRENCYAPI_KEY`/`LLM_OPENAI_KEY` -- no `N8N_API_URL`/
`N8N_API_KEY`, which `make import`/`make drift` require to reach the local
Docker n8n container on the Engineer's own machine. Neither the Docker
daemon nor the local n8n API is reachable from this execution environment.
**`make import FILE=ai-chat-currency-agent.json` and
`make drift ID=<docker_workflow_id> FILE=ai-chat-currency-agent.json` could
not be run by the Executor and must be run by the Engineer locally.**
A2 (Docker instance shows the same behavior) is therefore unverified.

### Docs (A5) -- DONE
`docs/workflows/chat-agent/README.md`: added the error branch to the node
diagram and a new "Agent-level failure handling" section describing the
behavior in plain language (no task/requirement ids in the prose, per the
`docs/` rules).

## Open issue for Validator
- id: EXEC-1
  type: architecture
  severity: blocking (for A2/A3 specifically; A1/R1/R2 are independently
    satisfied and verified)
  ref: "R3/A2 -- Docker sync and drift-check cannot be executed by the
    Executor in this environment (no Docker/API access in the session
    shell); requires the Engineer to run `make import` + `make drift`
    locally and report back, or to grant equivalent access."
