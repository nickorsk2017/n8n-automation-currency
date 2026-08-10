# Workflow 1 — Daily Currency Rate Loader

File: `workflows/1-currency-rate-loader.json`

Pulls the latest exchange rates once a day and writes them into the
`currency_rates` Data Table.

## Flow

```
Schedule Trigger - Daily FX Pull        06:00 UTC, every day
   └─ Set - Loader Config               base_currency = USD
      └─ HTTP Request - Fetch Latest Rates   GET /latest
         ├─ IF - Response OK                 does the payload contain rates?
         │   └─ Code - Rates To Rows         { EUR: 0.86, ... } → one row per pair
         │      └─ IF - Rows Valid           every row complete and numeric?
         │         └─ Split Out - Rows To Items
         │            └─ Data Table - Upsert Rate Row
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

## The base currency is configurable

`Set - Loader Config` holds `base_currency` as a single field, and the HTTP node
reads it from there rather than embedding it in the URL. Changing which base
currency is loaded is a one-field edit, and the value is carried into every
stored row.

## What counts as failure

Three things can go wrong, and all three are treated as failure rather than as
an empty result:

| Stage | Trigger |
|---|---|
| `HTTP_FETCH` | The API call failed — timeout, rate limit, non-2xx status, or an error body |
| `API_RESPONSE` | The call returned, but with no usable rate data |
| `ROW_VALIDATION` | The transformed rows were empty, incomplete, or had a non-numeric rate |

All three converge on `Code - Build Error Record`, which emits:

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

## Bad data never reaches the table

The two validation gates sit before the first write, and nothing on the error
path connects to `Data Table - Upsert Rate Row`. A run either writes a complete,
validated set of rates or writes nothing at all. There is no path that leaves
the table half updated with a partial API response.

## Re-running is safe

The write is an upsert matched on `(base_currency, target_currency)`, so running
the loader twice in one day refreshes the existing rows rather than duplicating
them. Manual test runs are safe for the same reason.

## When it fails, what to do

1. Open the failed execution and read the `Code - Build Error Record` output —
   `failure_stage` says which of the three things happened.
2. `HTTP_FETCH` with a 4xx usually means the API key or the base currency; the
   free tier's monthly quota is also visible in the response headers.
3. `API_RESPONSE` or `ROW_VALIDATION` means the API answered with something
   unexpected — worth checking whether freecurrencyapi changed its response
   shape.
4. The table is untouched either way, so re-running after a fix is safe and
   needs no cleanup.
