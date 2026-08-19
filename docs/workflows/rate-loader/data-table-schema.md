# Data table: `currency_rates`

One n8n Data Table holds every rate the system knows. Both workflows depend on
it: the loader writes it, the chat agent's tool reads it.

## Columns

| Column | Type | Example | Meaning |
|---|---|---|---|
| `base_currency` | string | `USD` | The currency the rate is quoted against |
| `target_currency` | string | `JPY` | The currency being quoted |
| `rate` | number | `157.7800165274` | How many units of target equal one unit of base |
| `fetched_at` | string (ISO 8601) | `2026-08-09T06:00:24.163Z` | When this rate was pulled from the API |

The logical key is the pair `(base_currency, target_currency)`. A row means:
one unit of `base_currency` was worth `rate` units of `target_currency` as of
`fetched_at`.

## Why this shape

**The key follows the API.** freecurrencyapi's `/latest` endpoint returns one
object keyed by target currency for a single base. One call therefore produces
exactly one row per target currency, and the natural key falls straight out of
the response. Storing the base in its own column rather than assuming it keeps
the door open to loading a second base later without a migration — and the base
the loader uses is itself a table value, see [the config table](config-table.md).

**Upsert, not append.** The loader matches on both key columns and updates in
place. A repeated run — a retry, a manual test, a backfill — refreshes the same
33 rows instead of growing the table forever. This is what makes the daily job
safe to re-run, and it is visible in the data: after a second run on the same
day, `createdAt` still shows the original 06:00 write while `updatedAt` moves.

**`fetched_at` is stored per row, not per run.** The chat agent has to tell the
user how old a rate is, and it reads rows, not runs. Keeping the timestamp on
the row means the tool can report freshness without a second lookup, and means a
partially refreshed table would still report each rate honestly.

**Rates are stored, conversions are not.** There is no `converted_amount`
anywhere in the table. Conversions are computed per request from these rows, so
the table stays proportional to the number of currencies rather than to the
number of questions asked.

## Cross rates are derived, not stored

The loader stores only `base → X` for the single configured base. A question like "CAD to AUD" is answered by
dividing one stored rate by the other, at query time, inside the tool.

The alternative — storing every ordered pair — would turn 33 rows into over a
thousand, all derived from the same 33 numbers, and would need every one of them
rewritten on each daily run. The arithmetic is one division. See
[the chat agent](../chat-agent/) for how the tool does it,
including the special case where one side of the conversion is the base currency
itself and its rate is exactly 1.

The consequence worth knowing: precision is limited by float arithmetic on two
stored rates, and results are rounded to six decimal places. For a conversation
about money that is comfortably sufficient; for settlement-grade figures it
would not be.
