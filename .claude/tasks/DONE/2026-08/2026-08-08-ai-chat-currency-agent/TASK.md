# TASK — 2026-08-08-ai-chat-currency-agent
owner: Engineer
immutable: true

## Requirements
- R1: Add a Chat Trigger node to Workflow 2 (`workflows/2-ai-chat-currency-agent.json`)
  that exposes the agent through n8n's native chat interface. The agent's opening
  message must greet the user and explain what it can do (convert currency amounts
  using live-ish stored FX rates).
- R2: Add an AI Agent node (LangChain Agent) backed by an LLM Chat Model node. Any
  provider is acceptable (OpenAI, Anthropic, Ollama, etc.); the provider's API key
  must come from an n8n credential, never a literal in the exported JSON, per root
  CLAUDE.md secrets rule. Follow the pattern already used by `LLM_OPENAI_KEY` in
  `.env.example` unless Planner justifies a different provider.
- R3: Implement a custom tool node named `convert_currency` that the AI Agent can
  call. Inputs: `amount` (number), `from_currency` (string, 3-letter code),
  `to_currency` (string, 3-letter code). The tool reads from the `currency_rates`
  Data Table populated by Workflow 1 (see `docs/data-table-schema.md`) and returns:
  the converted amount, the exchange rate used, and when that rate was last fetched
  (`fetched_at`), so the user can judge data freshness (R5).
- R4: The agent must handle natural-language conversion queries end-to-end,
  including follow-up questions that rely on prior conversation context (e.g. "and
  in GBP?"), by relying on the LLM's tool-calling plus n8n's chat memory — Planner
  to choose the memory node/pattern.
- R5: Tool response must always include a freshness indicator (the stored
  `fetched_at` timestamp for the rate used), not just the numeric result.
- R6: Error handling, at both tool and agent level, for: unknown/invalid currency
  codes (not present in `currency_rates`), missing or stale data (e.g. table empty
  or no row for the requested pair), `amount` == 0 or negative, and non-numeric
  `amount` input. The tool must return a structured error rather than throwing, and
  the agent's system prompt must instruct it to explain the problem in plain
  language rather than surfacing raw error text/stack traces to the user.
- R7: Document the agent's system prompt and the `convert_currency` tool's
  input/output contract and error cases in `docs/` (e.g.
  `docs/agent-system-prompt.md` and/or `docs/convert-currency-tool.md` — Planner to
  decide exact file split), per root CLAUDE.md ("docs/ — ... agent system prompt,
  tool design notes").
- R8: Produce a successful test execution demonstrating: (a) a direct conversion
  query, (b) a follow-up query, (c) at least one graceful-error case (e.g. unknown
  currency code). Per the precedent set in the DONE loader task, recorded n8n MCP
  execution evidence in EXEC.md is acceptable in place of a screenshot; if a
  screenshot is captured it goes to `screenshots/`, not this repo's Engineer email
  workflow (Planner/Executor to confirm which applies).

## Acceptance
- A1: `workflows/2-ai-chat-currency-agent.json` contains a Chat Trigger with a
  greeting/capability-explaining opening message.
- A2: The workflow contains an AI Agent node wired to an LLM Chat Model node via a
  credential reference only (no literal key).
- A3: A tool node named `convert_currency` exists with `amount` (number),
  `from_currency` (string), `to_currency` (string) inputs, wired as a tool input to
  the AI Agent node.
- A4: The tool's output includes converted amount, rate used, and `fetched_at`
  freshness timestamp, sourced from the `currency_rates` Data Table.
- A5: The workflow includes a memory mechanism so follow-up questions resolve
  correctly without repeating the original amount/currencies.
- A6: Unknown currency codes, missing/empty data, non-numeric amount, and
  amount <= 0 are all handled without an unhandled exception; the agent's response
  in each case is a plain-language explanation, not a raw error/stack trace.
- A7: `docs/` contains the system prompt text and the tool's documented
  input/output/error contract.
- A8: No secrets appear anywhere in `workflows/2-ai-chat-currency-agent.json`.
- A9: EXEC.md (and/or `screenshots/`) records a real executed run covering a normal
  conversion, a follow-up, and a graceful error case.

## Constraints
- Follow root CLAUDE.md n8n conventions: descriptive typed node names
  (`<Kind> - <What>`), `notes` on every non-obvious node referencing the requirement
  id it satisfies, prefer built-in nodes over Code nodes (a Code node is justified
  here mainly for the conversion arithmetic / structured error shaping inside the
  `convert_currency` tool, where built-ins cannot express the logic).
- Reads from the `currency_rates` Data Table schema as defined in
  `docs/data-table-schema.md`; if a change to that schema is needed, Planner must
  call it out explicitly rather than editing it ad hoc.
- All persisted content (TASK/PLAN/EXEC/VALIDATION/JSON node names/notes/docs) in
  English, per root CLAUDE.md language rule.
- Builds on top of the DONE loader task
  (`2026-08-08-2026-08-08-loader-fetch-upsert`) — Workflow 1 and the
  `currency_rates` table already exist; this task only adds Workflow 2 and does not
  modify Workflow 1.
