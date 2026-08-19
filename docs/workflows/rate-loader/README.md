# Workflow 1 — Daily Currency Rate Loader

File: `workflows/currency-rate-loader.json`

Pulls the latest exchange rates once a day and writes them into the
`currency_rates` Data Table.

## Flow

```
Schedule Trigger - Daily FX Pull        06:00 UTC, every day
   └─ Data Table - Get Base Currency Config   config table, base_currency row
      └─ IF - Base Currency Configured        is a base currency set at all?
         └─ HTTP Request - Fetch Latest Rates   GET /latest
         ├─ IF - Response OK                 does the payload contain rates?
         │   └─ Code - Rates To Rows         { EUR: 0.86, ... } → one row per pair
         │      └─ IF - Rows Valid           did we get at least one row at all?
         │         └─ Split Out - Rows To Items
         │            └─ IF - Row Fields Valid    this one row complete and numeric?
         │               ├─ Data Table - Upsert Rate Row
         │               └─ Code - Log Skipped Row   (logged, run still succeeds)
         └─ (any failure) ─────────────► Code - Build Error Record
                                            └─ Stop and Error - Fail Loader Run
```

## The schedule is genuinely UTC

n8n resolves a Schedule Trigger's hour against the *instance* timezone, not the
node, so "06:00" alone would mean different things on different stands. The
workflow therefore pins `settings.timezone = "UTC"` in its own definition, which
travels with the exported file, and `docker-compose.yml` additionally sets
`GENERIC_TIMEZONE=UTC` and `TZ=UTC` so the container clock agrees.

To change the time, edit `triggerAtHour` / `triggerAtMinute` on the trigger node
and export the workflow back to the repository.

## The base currency lives in a data table

The loader holds no base currency of its own. `Data Table - Get Base Currency
Config` reads the `base_currency` row of the shared `config` table at the start
of every run, and that value flows into the API call, into every stored row, and
into the error record. Changing the base is an edit to one table cell — no
workflow edit, no re-export, no re-import. See
[the config table](config-table.md) for its shape, the default, and how the
default is seeded.

`IF - Base Currency Configured` gates the rest of the run on that value: an
absent or blank one fails at stage `CONFIG` rather than falling back to a
currency the workflow picked. A fallback would be indistinguishable from a
correct run in the execution list while quietly filling the table against the
wrong base.

**Why not an n8n Variable.** `{{ $vars.BASE_CURRENCY }}` would be the idiomatic
way to make a value editable outside the workflow, but Variables are gated
behind an Enterprise license on self-hosted Community edition — the stand this
repository runs (`docker-compose.yml`, `make up`) — and free only on n8n Cloud.
The config table gives the same "edit it in the UI, no export" property with no
licence attached, and generalises to further settings as rows.

## What counts as a run failure

Four things can fail the whole run (mark the execution red, write nothing):

| Stage | Trigger |
|---|---|
| `CONFIG` | No usable `base_currency` row in the `config` table |
| `HTTP_FETCH` | The API call failed — timeout, rate limit, non-2xx status, or an error body |
| `API_RESPONSE` | The call returned, but with no usable rate data |
| `ROW_VALIDATION` | The transformed `rows` array came back empty — no currency pairs at all |

A single malformed row inside an otherwise-good response (missing currency
code, non-numeric or `NaN` rate) is **not** one of these — see "Bad data
never reaches the table" below.

`HTTP_FETCH` is the last resort, not the first response to a transient error:
`HTTP Request - Fetch Latest Rates` retries a failed call up to 3 times, waiting
2 seconds between attempts, before it is treated as a failure at all. A single
momentary timeout or a fleeting rate-limit response from freecurrencyapi no
longer fails the day's run on its own — only a request that is still failing
after all three attempts reaches `HTTP_FETCH`.

All four converge on `Code - Build Error Record`, which emits:

```json
{
  "workflow": "Daily Currency Rate Loader",
  "failure_stage": "HTTP_FETCH",
  "error_message": "freecurrencyapi request failed: 422 - The selected base currency is invalid.",
  "base_currency": "USD",
  "failed_at": "2026-08-09T16:06:00.221Z"
}
```

`Stop and Error - Fail Loader Run` then throws, so **the execution is marked
failed in n8n's execution list**. This is deliberate and it is a change in
behaviour: previously a failed fetch produced a green run with no rates loaded,
which meant a loader could be broken for a week without anyone noticing. A red
run is the signal; the record above is the diagnosis.

## Bad data never reaches the table, and one bad row doesn't block the rest

Validation happens at two levels. `IF - Rows Valid` is a structural gate: if
the API response yielded no rows at all, the run fails outright via
`Code - Build Error Record` / `Stop and Error - Fail Loader Run` and nothing
is written. If at least one row came back, `IF - Row Fields Valid` then checks
each currency pair individually, after `Split Out - Rows To Items`: a row
missing its currency code, `fetched_at`, or with a non-numeric/`NaN` rate is
routed to `Code - Log Skipped Row` instead of the Data Table — logged, but
**not** thrown, so it does not fail the run. Every other, valid row in the
same execution still reaches `Data Table - Upsert Rate Row`. A single bad
currency in the API response can no longer block that day's update for every
other currency.

## Evaluations are not wired here

Unlike the chat agent (see [Chat agent](../chat-agent/)), this workflow does
not use n8n's built-in Evaluations. That feature judges a workflow's output
for quality against an expected answer — a good fit for an LLM's
free-text response, a poor one here: given a fixed sample API response, this
loader's transform, validation, and upsert are pure functions of their
input, so the correct output is a single exact value, not something worth
judging for similarity. That is what a unit/integration test checks (see
the root README's trade-offs), not an Evaluation-node comparison.

## Re-running is safe

The write is an upsert matched on `(base_currency, target_currency)`, so running
the loader twice in one day refreshes the existing rows rather than duplicating
them. Manual test runs are safe for the same reason.

## When it fails, what to do

1. Open the failed execution and read the `Code - Build Error Record` output —
   `failure_stage` says which of the four things happened.
2. `CONFIG` means the stand was never provisioned, or the `base_currency` row
   was blanked: run `make setup-data-table`, or set the value in the table.
3. `HTTP_FETCH` with a 4xx usually means the API key or the base currency; the
   free tier's monthly quota is also visible in the response headers.
4. `API_RESPONSE` or `ROW_VALIDATION` means the API answered with something
   unexpected — worth checking whether freecurrencyapi changed its response
   shape.
5. The table is untouched either way, so re-running after a fix is safe and
   needs no cleanup.
