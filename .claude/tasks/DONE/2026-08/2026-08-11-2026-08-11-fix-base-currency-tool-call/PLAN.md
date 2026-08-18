# PLAN — 2026-08-11-2026-08-11-fix-base-currency-tool-call

## v1

### Scope
Two edits inside `workflows/ai-chat-currency-agent.json`, plus a docs sync. No new
nodes, no schema change, no new dependencies.

### R1 — NO_RATE_DATA guard fix (`Code - Compute Conversion`)
Current guard only fires when *both* `from` and `to` are non-base currencies,
so a base-currency leg (e.g. `to == 'USD'`) with a genuinely empty table falls
through to `findRate()` and is misreported as `UNKNOWN_CURRENCY`. Reframe the
guard around the *non-base leg(s)* rather than requiring both legs to be
non-base: for each side that is not the base currency, if the table has zero
rows overall, that side's cause is "no data loaded", not "code not recognized" —
report `NO_RATE_DATA`. When the table is non-empty (some rows exist) but a
specific non-base side still has no matching row, `UNKNOWN_CURRENCY` remains
correct (A2) since the loader is running and simply doesn't track that code.
Net effect: the zero-rows check must trigger whenever at least one requested
currency is not the base currency and the table returned nothing, not only
when neither side is the base currency.

### R2 — System prompt hardening (`AI Agent - Currency Assistant`.systemMessage)
Node-level forcing is not possible (grounded constraint: no `tool_choice` param
on `@n8n/n8n-nodes-langchain.agent` v3.1). Mitigation is prompt-only: extend
Rule 1 with an explicit clause that the "always call the tool" instruction has
no exception for conversions where one side is the base currency (USD) —
name the failure mode directly (e.g. "do not skip the tool because you think a
USD leg is trivial or rate 1"), so the model cannot rationalize a shortcut.
Keep the rest of the prompt (rules 0, 2-5) unchanged; this is an additive
clarification to Rule 1, not a rewrite.

### R3 — Docs sync (`docs/workflows/chat-agent/README.md`)
Update the `error_code` table's `NO_RATE_DATA` row description to note it also
covers an empty table when the request includes the base currency. Update the
"System prompt" section's Rule 1 quoted text to match the strengthened
wording verbatim (docs must mirror the workflow JSON exactly, not paraphrase).
Add one short implementation-note sentence near the system-prompt discussion
that the Agent node has no mechanical tool-forcing option, so this reliability
guarantee is prompt-level only — phrased as current system behavior, not as a
record of investigation/history (root CLAUDE.md docs rule).

### R4 — Test evidence
Executor uses n8n MCP `test_workflow`/`execute_workflow` (or direct tool-path
execution against `Execute Workflow Trigger - Convert Currency Tool`) for three
cases, run against a temporarily emptied vs. populated `currency_rates` table
as needed:
(a) `EUR -> USD` (or equivalent base-currency leg) with zero rows in the table
    -> expect `success:false, error_code: NO_RATE_DATA`.
(b) same pair with the table populated -> expect `success:true` with a correct
    cross-rate result.
(c) `EUR -> JPY` (neither leg is base currency) -> unaffected by the guard
    change, behaves exactly as before (regression check, not a new case).
Record inputs/outputs of each run in EXEC.md; restore any seeded/cleared table
state afterward so the live instance is left as found.

### Sequencing
1. Executor edits `Code - Compute Conversion`'s guard logic (R1).
2. Executor edits `AI Agent - Currency Assistant`.systemMessage Rule 1 (R2).
3. Executor re-exports the workflow to `workflows/ai-chat-currency-agent.json`
   (root CLAUDE.md export discipline).
4. Executor runs the three test cases (R4) and records results.
5. Executor updates `docs/workflows/chat-agent/README.md` (R3) to match the
   final, tested wording/behavior exactly.

### Risks
- Loosening the guard too broadly (e.g. dropping the base-currency check
  entirely) would make `NO_RATE_DATA` fire even when a specific non-base
  currency is simply unsupported on a populated table — Executor must keep the
  two error codes distinguishable per A2, not collapse them.
- Prompt wording must stay declarative and short (per root CLAUDE.md prompt
  precedent) — do not balloon Rule 1 into a paragraph; one added sentence/clause
  is sufficient.

STATE: stage=PLANNED, next_actor=Executor, plan_version=1
