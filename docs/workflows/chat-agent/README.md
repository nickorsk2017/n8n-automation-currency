# Workflow 2 — AI Chat Currency Agent

File: `workflows/2-ai-chat-currency-agent.json`

A chat interface where a user asks a currency question in ordinary language and
an LLM agent answers it using stored rates.

## Two entry points in one file

The file contains two disconnected chains, which is intentional:

```
Chat Trigger - Currency Agent Entry
   └─ AI Agent - Currency Assistant
        ├─ OpenAI Chat Model - GPT        the model
        ├─ Memory - Chat Window           follow-up questions
        └─ convert_currency               the tool

Execute Workflow Trigger - Convert Currency Tool     ← the tool's body
   └─ Code - Validate Conversion Input
      └─ IF - Input Valid
         ├─ Data Table - Get Rate Rows
         │    └─ Code - Compute Conversion
         └─ NoOp - Log Tool Error
```

The tool node calls back into *this same workflow* by id, reaching the second
trigger. The reason is that a sandboxed code tool cannot query a Data Table —
only a workflow can — and the alternative was a third exported file whose only
job was to hold the tool. One workflow, one file, at the cost of a canvas with
two unconnected chains on it.

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
  "fetched_at": "2026-08-09T06:00:24.163Z"
}
```

`fetched_at` is the freshness of the rate used. When a conversion combines two
stored rates, the *older* of the two timestamps is reported, so the figure is
never presented as fresher than its stalest input.

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
| `NO_RATE_DATA` | The table is empty — the loader has not run yet |

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
   stored rate.
2. Extract the amount, from_currency, and to_currency from the user's message
   (and from earlier turns in the conversation for follow-up questions such as
   'and in GBP?' or 'what about CAD?'). Use standard 3-letter ISO currency codes.
3. When you receive the tool's result:
   - If success is true, tell the user the converted amount, the exchange rate
     used, and when that rate was last fetched (fetched_at), phrased in plain,
     friendly language.
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

Three things it is doing deliberately. Rule 1 exists because an LLM will happily
produce a plausible exchange rate from memory; forbidding that is what makes the
answers trustworthy. Rule 3 keeps internal error codes out of the conversation.
Rule 4 stops the agent guessing a missing amount, which is worse than asking.

## Follow-up questions

`Memory - Chat Window` keeps recent turns per chat session, so "and in GBP?"
resolves against the previous question. When there is no such context — a fresh
session, or a genuinely ambiguous request — rule 4 applies and the agent asks
rather than assumes.

## Requirements

The `OpenAI Chat Model - GPT` node needs an OpenAI credential configured in n8n.
The exported file references it by name and id only; no key value is stored in
the repository. The workflow must also be **active**, because the tool node
calls the workflow by id and n8n refuses to execute an inactive workflow even
when it is calling itself.
