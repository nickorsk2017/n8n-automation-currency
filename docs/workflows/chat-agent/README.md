# Workflow 2 — AI Chat Currency Agent

File: `workflows/ai-chat-currency-agent.json`

A chat interface where a user asks a currency question in ordinary language and
an LLM agent answers it using stored rates.

## Two entry points in one file

The file contains two disconnected chains, which is intentional:

```
Chat Trigger - Currency Agent Entry
   └─ Guardrails - Screen User Input
        ├─ OpenAI Chat Model - Guardrails       its own model
        ├─ (pass)  AI Agent - Currency Assistant
        │     ├─ OpenAI Chat Model - GPT        the model
        │     ├─ Memory - Chat Window           follow-up questions
        │     ├─ convert_currency               the tool
        │     ├─ (success) Evaluation - Write Actual Answer
        │     └─ (error)   Execute Workflow - Log Agent Error
        │                     └─ Set - Format Agent Error
        ├─ (fail)  Execute Workflow - Log Guardrail Outcome
        │             └─ Set - Format Guardrail Refusal
        └─ (error) Execute Workflow - Log Guardrail Error
                      └─ Set - Format Guardrail Error

Execute Workflow Trigger - Convert Currency Tool     ← the tool's body
   └─ Code - Validate Conversion Input
      └─ IF - Input Valid
         ├─ Data Table - Get Rate Rows
         │    └─ Code - Compute Conversion
         └─ Execute Workflow - Log Tool Error
```

Every `Execute Workflow - Log ...` node calls the shared `Error Logger`
sub-workflow — see `docs/workflows/error-logger/` for its contract and schema.

The tool node calls back into *this same workflow* by id, reaching the second
trigger. The reason is that a sandboxed code tool cannot query a Data Table —
only a workflow can — and the alternative was a third exported file whose only
job was to hold the tool. One workflow, one file, at the cost of a canvas with
two unconnected chains on it.

## Guardrail

`Guardrails - Screen User Input` sits between the chat trigger and the agent and
screens every user message before the agent ever sees it. It runs two checks
against the message text: `jailbreak` (attempts to override, replace, reveal, or
ignore the assistant's instructions or role) and `topicalAlignment`, configured
with a custom prompt scoping the assistant to currency conversion only, so
anything else (weather, general knowledge, code execution, etc.) is flagged too.
It has its own dedicated `OpenAI Chat Model - Guardrails` node for the
classifier model, separate from the agent's `OpenAI Chat Model - GPT` -- both
point at the same pre-existing OpenAI credential, so no *new* credential is
needed, but each AI node (agent, guardrail) gets its own model node rather
than one node's output fanning out to both.

Pass continues to `AI Agent - Currency Assistant` as normal. Fail routes to
`Execute Workflow - Log Guardrail Outcome` and then to
`Set - Format Guardrail Refusal`, which returns the fixed English message
`"Invalid request. I can only help with currency conversion."` regardless of the
language the user wrote in, without echoing the flagged text back and without
ever reaching the agent or the `convert_currency` tool. This replaces what used
to be a "Rule 0" instruction inside the agent's own system prompt — the refusal
behavior is unchanged, but it is now enforced by a dedicated node instead of by
prompt text.

### When the classifier itself fails

The guardrail node does not throw when its own model call fails. It catches the
exception, marks every check it could not evaluate as triggered, and emits the
item on **Fail** — failing closed, which is the safe direction: unscreened input
never reaches the agent. The visible consequence is that an infrastructure
failure (an exhausted OpenAI quota, a sustained rate limit) is answered with the
refusal message above, so a perfectly valid conversion question can be told it is
invalid. That is a known, accepted trade-off rather than an oversight.

What makes it diagnosable is `Execute Workflow - Log Guardrail Outcome`, which
sits on the Fail branch and records every outcome. Its `message` names each
triggered check and says which kind of outcome it was:

```
topicalAlignment (input rejected) [execution 171]
jailbreak (classifier failed: Guardrail validation failed: Bad request - ...) [execution 171]
```

So the graph does not branch on the distinction, but the `error_log` row still
carries it. The consequence worth knowing about is that ordinary policy refusals
are logged alongside genuine failures — `error_log` is a record of every
guardrail outcome, not only of things that broke.

### Why the logged cause is vague, and what to do about it

The exception text a failed check reports is the generic wrapper, not the actual
cause. When the classifier's model call fails, n8n raises a `NodeApiError` with
two fields — `message` (`"Bad request - please check your parameters"`) and
`description` (`"It looks like you've used all your free n8n AI credits..."`) —
and the guardrail node keeps only the first when packing the failure into its
result. By the time the item reaches the Fail branch the useful half is gone,
and no expression can recover it.

That is why every logged message ends with `[execution <id>]`. The full error
does survive in the execution record, so the row cannot state the cause but can
say exactly where to read it: open that execution and inspect the
`OpenAI Chat Model - Guardrails` sub-node.

Worth knowing: this vagueness is partly an artefact of running on n8n's built-in
AI credits, which proxy OpenAI through `ai-assistant.n8n.io`. A workflow using
its own OpenAI credential gets the provider's real error text.

The other three loggers carry the same `[execution <id>]` suffix, for the same
reason — a row read weeks later is worth little without a way back to the run
that produced it. Two of them (`Execute Workflow - Log Agent Error` and
`Execute Workflow - Log Guardrail Error`) are fed by real n8n error outputs
rather than by the guardrail's lossy packing, so they also record
`$json.error.description` when it is present.

The third branch, `(error)`, exists for a failure the node's own handler does not
cover and that does reach n8n as a thrown error. It is normally idle.

The evaluation dataset path (`Evaluation Trigger - Read Test Dataset`) bypasses
the guardrail and feeds the agent directly, since it replays a fixed set of
known-valid conversion questions rather than live user input.

## Agent-level failure handling

`AI Agent - Currency Assistant` is configured with `onError: continueErrorOutput`
(on top of its existing `retryOnFail`), so a sustained failure of the underlying
LLM call — most commonly rate limiting on a free or trial API tier, but also
other OpenAI-side errors — no longer fails the execution silently. The item is
routed to a second output branch instead: `Execute Workflow - Log Agent Error`
calls the shared `Error Logger` sub-workflow to record the failure, then
`Set - Format Agent Error` returns a fixed message in the same `output` field the
agent's own successful runs use, so it reaches the chat user exactly like a
normal reply. The `convert_currency` tool branch has an equivalent pattern
(`Execute Workflow - Log Tool Error`) for malformed tool input, calling the same
shared logger.

`Set - Format Agent Error` and `Set - Format Guardrail Error` both hold a plain
string, not an expression:

> An error occurred - please try again. (The error has been logged for the system
> administrator and will be fixed shortly.)

They used to interpolate the underlying error message, which put raw provider
text — including HTML markup, in one observed case — in front of the user, who
can do nothing with it. Keeping the value a literal rather than an expression
means no error text can leak into it by construction. Nothing is lost: the raw
error is already in `error_log`, which is where someone who can act on it will
look.

## How a reply reaches the chat widget

`Chat Trigger - Currency Agent Entry` uses `responseMode: "lastNode"`. That
choice imposes a contract on the whole graph, and it is worth stating because
nothing enforces it automatically:

> Every node that can be the **last** one on a chat path must emit
> `{ output: "<reply text>" }`. A side-effect node — a Data Table insert, an
> `Execute Workflow` call, an evaluation node — must never be last.

Today four nodes can end a chat run, and all four are `Set` nodes emitting
`output`: `Set - Format Agent Reply` (success), `Set - Format Agent Error`,
`Set - Format Guardrail Refusal`, `Set - Format Guardrail Error`. The logging
nodes satisfy the rule by sitting mid-chain with a `Set` after them rather than
at the end of their branches.

`Set - Format Agent Reply` exists purely to satisfy this contract. Without it
the success path would end at `Evaluation - Write Actual Answer`, whose job is
the dataset-replay trigger and whose pass-through behaviour is not something to
depend on. It sources the reply from the agent explicitly:

```
{{ $('AI Agent - Currency Assistant').item.json.output }}
```

The alternative mode, `streaming`, was in use previously and returned nothing at
all: it makes the widget wait for stream chunks from an Agent node with
streaming enabled, and this workflow has no streaming producer on any path. The
symptom is a widget reply reading `[No response received...]` while the
execution itself completes successfully — which is why execution data is not
evidence that the chat works. Only the widget is.

## The `convert_currency` contract

**Input**

| Field | Type | Notes |
|---|---|---|
| `amount` | number | Must be greater than zero |
| `from_currency` | string | Three-letter code, case-insensitive |
| `to_currency` | string | Three-letter code, case-insensitive |

**Success**

```json
{
  "success": true,
  "amount": 100,
  "from_currency": "EUR",
  "to_currency": "JPY",
  "converted_amount": 182370.72,
  "rate": 1823.7072,
  "fetched_at": "2026-08-09T06:00:24.163Z",
  "is_stale": false
}
```

`fetched_at` is the freshness of the rate used. When a conversion combines two
stored rates, the *older* of the two timestamps is reported, so the figure is
never presented as fresher than its stalest input.

`is_stale` is `true` when that timestamp is more than `STALE_THRESHOLD_HOURS`
(36, a named constant in `Code - Compute Conversion`, next to `baseCurrency`)
old. The loader runs once a day, so 36h tolerates one missed or delayed run
before warning. When either side of a conversion is the base currency itself,
its synthetic `fetched_at` is `null` and is excluded from the age check — a
rate of exactly 1 by definition can't be stale. `is_stale` only ever appears
on a successful response; it plays no part in any `error_code` path below.

**Failure**

```json
{ "success": false, "error_code": "UNKNOWN_CURRENCY", "message": "\"XYZ\" is not a supported currency code." }
```

| `error_code` | Cause |
|---|---|
| `INVALID_AMOUNT` | Amount missing or not a number |
| `NON_POSITIVE_AMOUNT` | Amount is zero or negative |
| `INVALID_CURRENCY_CODE` | Not a three-letter code |
| `UNKNOWN_CURRENCY` | Well-formed code, but no rate stored for it |
| `NO_RATE_DATA` | No rows were found for a requested non-base currency — the loader has not run yet. This also covers a base-currency (USD) leg: e.g. `EUR -> USD` on an empty table reports `NO_RATE_DATA`, not `UNKNOWN_CURRENCY`, since the missing data is the real cause, not an unrecognized code. |

Codes are for the agent, not the user. The prompt requires the agent to
translate them; the user should never see the string `UNKNOWN_CURRENCY`.

## How the conversion is computed

Validation first: the amount is coerced and checked for being numeric and
positive, and both codes are trimmed, upper-cased and matched against `^[A-Z]{3}$`.
Invalid input never reaches the database.

Then the table is read and the cross rate derived:

```
effective_rate = rate(to_currency) / rate(from_currency)
converted      = amount × effective_rate
```

with `rate(USD) = 1` by definition, since the stored rates are quoted against
USD. So `EUR → JPY` divides the stored JPY rate by the stored EUR rate, while
`USD → JPY` is just the stored JPY rate. Results are rounded to six decimals.

One subtlety worth knowing about: the Data Table lookup runs with
`alwaysOutputData` enabled. Without it, a lookup matching nothing produces zero
items, n8n drops the branch, and the tool returns nothing at all instead of a
usable error — the agent would then have no idea why it got silence. With it,
the empty result reaches the code that turns "no rows" into `UNKNOWN_CURRENCY`
or `NO_RATE_DATA`.

## Greeting

The chat trigger opens with:

> Hi! I'm your currency conversion assistant. Ask me things like "How much is
> 100 EUR in JPY?" or "Convert 50 GBP to USD", and I'll look up the latest
> stored exchange rate for you. I can also answer follow-up questions like "and
> in AUD?".

## System prompt

```
You are a currency conversion assistant embedded in an n8n chat. You help users
convert amounts between currencies using exchange rates stored in the
currency_rates data table (refreshed daily by a separate loader workflow).

Rules:
1. For ANY request to convert an amount from one currency to another, always
   call the convert_currency tool. Never calculate the conversion yourself, even
   for currencies you think you know the rate for -- only the tool has the live
   stored rate. This applies with NO exception when one side of the conversion
   is the base currency (USD): do not skip the tool because a USD leg seems
   "trivial" or you assume its rate is 1 -- the tool is still the only source
   of the current stored rate and its freshness (fetched_at/is_stale) for the
   other currency, so always call it for USD conversions too (e.g. "100 EUR to
   USD", "50 USD to JPY").
2. Extract the amount, from_currency, and to_currency from the user's message
   (and from earlier turns in the conversation for follow-up questions such as
   'and in GBP?' or 'what about CAD?'). Use standard 3-letter ISO currency codes.
3. When you receive the tool's result:
   - If success is true, tell the user the converted amount, the exchange rate
     used, and when that rate was last fetched (fetched_at), phrased in plain,
     friendly language. If is_stale is true, explicitly add a plain-language
     warning that this rate may be out of date and that the user should
     double-check it before relying on it for a real transaction.
   - If success is false, NEVER show the raw error_code or any technical detail
     to the user. Instead, explain the problem in plain language:
     - INVALID_AMOUNT or NON_POSITIVE_AMOUNT: ask the user for a valid, positive
       amount.
     - INVALID_CURRENCY_CODE: ask the user for a valid 3-letter currency code
       (e.g. USD, EUR, JPY).
     - UNKNOWN_CURRENCY: tell the user that currency isn't currently
       supported/tracked, and ask if they meant a different code.
     - NO_RATE_DATA: tell the user exchange rate data hasn't been loaded yet and
       to check back soon.
4. If the user's request is ambiguous (missing amount or currency), ask a
   clarifying question instead of guessing.
5. Keep responses concise and conversational.
```

A few things it is doing deliberately. Prompt-injection and off-topic requests
are no longer handled here — that used to be a "Rule 0" checked ahead of
everything else, but it is now enforced upstream by `Guardrails - Screen User
Input` (see Guardrail, above), so this prompt only ever runs against
already-screened input. Rule 1 exists because an LLM will happily produce a
plausible exchange rate
from memory; forbidding that is what makes the answers trustworthy, and it
says so explicitly for base-currency (USD) legs because a rate of 1 is exactly
the kind of "I already know this" case a model is tempted to skip the tool
for. The AI Agent node has no `tool_choice`/forced-tool-use setting, so this
guarantee is enforced entirely by the prompt, not by node configuration. Rule
3 keeps internal error codes out of the conversation. Rule 4 stops the agent
guessing a missing amount, which is worse than asking.

## Follow-up questions

`Memory - Chat Window` keeps recent turns per chat session, so "and in GBP?"
resolves against the previous question. When there is no such context — a fresh
session, or a genuinely ambiguous request — rule 4 applies and the agent asks
rather than assumes.

## Evaluations

n8n's built-in Evaluations (Evaluation Trigger/node scoring a run against a
Data Table of expected Q&A) can grade this workflow's answers, but as of
today the judge/scoring model it runs against is Claude only — no other
LLM provider is a supported evaluation target yet.

The main chat branch carries two evaluation-only nodes, wired alongside
the regular chat path without changing it:

- `Evaluation Trigger - Read Test Dataset` reads the `chat_agent_eval_dataset`
  Data Table (columns `chatInput`, `expected_answer`) and feeds each row's
  `chatInput` into `AI Agent - Currency Assistant` the same way the Chat
  Trigger does.
- `Evaluation - Write Actual Answer` runs after the agent and writes its
  response back into the dataset's `actual_answer` column, satisfying the
  editor's "write workflow outputs back to dataset" step.

Scoring (the editor's optional "quality score" step) is skipped:
running it needs a `setMetrics` Evaluation node backed by a Claude/Anthropic
credential (the only supported judge model, per the constraint above), and
no such credential is provisioned on this instance — unlike
`FREECURRENCYAPI_KEY`/`LLM_OPENAI_KEY`, there is no `ANTHROPIC_API_KEY` in
`.env.example` or a `scripts/` step that imports one. Adding scoring means
provisioning that credential first. `chat_agent_eval_dataset` is
provisioned directly in the n8n instance (not by `make setup`, which only
provisions `currency_rates`); recreating it on a fresh instance is a
manual step for now.

## Requirements

The `OpenAI Chat Model - GPT` node needs an OpenAI credential. On the Docker
stand this is provisioned automatically — `make import-credentials` reads
`LLM_OPENAI_KEY` from `.env` and imports the credential under the fixed id
this workflow's JSON already references, so there is no manual credential
creation in the n8n UI. The exported file itself carries only that id/name
reference, never the key value.

The workflow must also be **active**, because the tool node calls the
workflow by id and n8n refuses to execute an inactive workflow even when it
is calling itself. This is likewise automatic: `scripts/import_workflow.sh`
activates the workflow via the n8n Public API right after import, so nothing
needs a manual Active toggle either.
