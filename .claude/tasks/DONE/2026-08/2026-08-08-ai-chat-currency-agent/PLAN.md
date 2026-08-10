# PLAN — 2026-08-08-ai-chat-currency-agent

## v1

### Architecture
Single exported file `workflows/2-ai-chat-currency-agent.json`, one workflow with
two entry points (both required so the custom tool can reach the Data Table node,
which a pure Code Tool cannot call):
1. **Chat path**: `Chat Trigger` -> `AI Agent` (LangChain Agent), wired to an
   `OpenAI Chat Model` sub-node, a `Simple Memory` (buffer window) sub-node, and a
   `convert_currency` tool sub-node of type `toolWorkflow` that calls back into
   this same workflow's second entry point.
2. **Tool path**: `Execute Workflow Trigger` (workflow input schema:
   `amount:number`, `from_currency:string`, `to_currency:string`) -> validation ->
   Data Table lookups -> Code node (rate math + response shaping) -> output. This
   is the actual implementation of `convert_currency`; the `toolWorkflow` node on
   the chat path is the tool's interface, this branch is its body.

Rationale for `toolWorkflow` over a Code Tool: only a real node (Data Table) can
query `currency_rates`; LangChain Code Tools run sandboxed JS with no node access.
`toolWorkflow` self-reference keeps everything in the one required export file
(root CLAUDE.md: "one file per workflow") instead of splitting into a second
workflow JSON.

### Data source (read-only; Workflow 1 unchanged)
Data Table `currency_rates` (id `tU2fbDOMyMnanxzS`), columns:
`base_currency, target_currency, rate, fetched_at`. Loader's `base_currency` is
fixed at `USD` (see `1-currency-rate-loader.json` "Set - Loader Config"). Rows are
`USD -> target_currency` rates only; the target-side of `base_currency` itself has
no row.

### Cross-rate formula (Code node, justified per root CLAUDE.md Code-node exception)
Given `rate(X)` = stored USD->X rate for a row where `target_currency = X`
(defined as 1 when `X == base_currency`, since that row doesn't exist in the
table):
- `rate(from) = 1` if `from_currency == base_currency`, else looked-up row rate.
- `rate(to)   = 1` if `to_currency   == base_currency`, else looked-up row rate.
- `effective_rate = rate(to) / rate(from)`
- `converted_amount = amount * effective_rate`
- `from_currency == to_currency`: short-circuit, `effective_rate = 1`, skip lookups.

### Validation / error contract (tool path, before any Data Table write... read here)
Order of checks, each returning a structured `{ success:false, error_code, message }`
tool result (never a thrown exception reaching the Agent):
1. `INVALID_AMOUNT` — `amount` is not a finite number (non-numeric input).
2. `NON_POSITIVE_AMOUNT` — `amount <= 0`.
3. `INVALID_CURRENCY_CODE` — `from_currency` or `to_currency` fails a 3-letter
   A-Z pattern.
4. `UNKNOWN_CURRENCY` — code well-formed but no matching row (and not equal to
   `base_currency`) in `currency_rates` for that side.
5. `NO_RATE_DATA` — table returns zero rows at all (loader has never run) — distinct
   from `UNKNOWN_CURRENCY` so the agent can explain "no data yet" vs "not
   supported."
Success path returns `{ success:true, amount, from_currency, to_currency,
converted_amount, rate, fetched_at }`. `fetched_at` is the older/most conservative
of the two rows' timestamps used for the conversion (or the single row's timestamp
if one side is `base_currency`), satisfying R5 freshness.

### Nodes (chat path)
- `Chat Trigger - Currency Agent Entry` (n8n-nodes-base.chatTrigger): initial
  message greets the user and explains it converts currency amounts using stored
  daily FX rates (R1).
- `AI Agent - Currency Assistant` (@n8n/n8n-nodes-langchain.agent): system prompt
  (documented verbatim in `docs/agent-system-prompt.md`) instructs it to (a) always
  call `convert_currency` for conversion requests rather than computing itself,
  (b) never expose raw error codes/stack traces, translate `error_code` to a plain
  sentence, (c) use conversation memory for follow-ups. Satisfies R1(explain
  capability)/R4/R6.
- `OpenAI Chat Model - GPT` (@n8n/n8n-nodes-langchain.lmChatOpenAi): credential
  reference only (n8n credential backed by `LLM_OPENAI_KEY`, per `.env.example`
  precedent), no literal key (R2).
- `Memory - Chat Window` (@n8n/n8n-nodes-langchain.memoryBufferWindow): session
  keyed on Chat Trigger's session id, enables follow-up questions (R4/A5).
- `Tool - Convert Currency` (@n8n/n8n-nodes-langchain.toolWorkflow): name
  `convert_currency`, description and JSON input schema for `amount`,
  `from_currency`, `to_currency`; targets this workflow's own id + the
  `Execute Workflow Trigger - Convert Currency Tool` node (R3).

### Nodes (tool path)
- `Execute Workflow Trigger - Convert Currency Tool`
  (n8n-nodes-base.executeWorkflowTrigger): declares the 3 typed inputs.
- `Code - Validate Conversion Input`: checks 1-3 above; on failure, sets
  `success:false` + `error_code` and short-circuits (IF node) around the Data
  Table lookups straight to output (R6).
- `IF - Input Valid`: branches error output vs. lookup path.
- `Data Table - Get Rate Rows` (n8n-nodes-base.dataTable, `getRows`, resource
  `row`): fetches all rows where `target_currency` is `from_currency` or
  `to_currency` (or zero rows if both equal `base_currency`).
- `Code - Compute Conversion`: applies the cross-rate formula above, applies
  checks 4-5, and shapes the final success/error object (R3/R5/R6). This node
  centralizes the arithmetic that no built-in node expresses — the Code-node
  exception in root CLAUDE.md and TASK Constraints.
- `NoOp - Log Tool Error` (mirrors Workflow 1's `NoOp - Log Loader Error`
  precedent): isolated branch for error-path visibility, does not affect the
  structured response returned to the Agent.

### Docs (R7)
- `docs/agent-system-prompt.md`: full system prompt text, plus a short rationale
  paragraph (why tool-first, why plain-language errors).
- `docs/convert-currency-tool.md`: input schema, output schema (success + each
  `error_code`), and the cross-rate formula (mirrors this PLAN's math so a
  reviewer doesn't need to open the Code node to understand it).
- `README.md`: append a "Workflow 2 — AI Chat Currency Agent" subsection once
  built (system prompt summary + trade-offs), consistent with the loader's
  existing "Data Table schema" section style.

### Test evidence (R8)
Executor runs the workflow via n8n MCP `test_workflow`/`execute_workflow` for:
(a) `100 EUR -> JPY` (cross-rate, both non-base), (b) a follow-up turn re-using
prior context, (c) an unknown code (e.g. `XYZ`) to prove the plain-language error
path. Recorded in EXEC.md per the loader-task precedent (A9); no screenshot
required in this repo.

### Open items for Executor
- Confirm via `list_credentials` whether an OpenAI credential already exists in
  the target n8n instance (loader task didn't need one); if none exists, Executor
  documents in EXEC.md that credential creation is a manual, non-repo step (same
  treatment as the `freecurrencyapi` Query Auth credential in root CLAUDE.md).
- Confirm exact `toolWorkflow` self-reference parameter shape via
  `get_node_types`/`get_sdk_reference` before wiring (SDK syntax is Executor's
  responsibility, not Planner's).

STATE: stage=PLANNED, next_actor=Executor, plan_version=1
