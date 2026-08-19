# Data table: `config`

A small key/value table holding settings the workflows read at run time rather
than carrying inside their own definitions. It is shared: any workflow on the
stand can read it, and new settings arrive as rows, not as schema changes.

## Columns

| Column | Type | Example | Meaning |
|---|---|---|---|
| `config_key` | string | `base_currency` | The setting's name |
| `config_value` | string | `USD` | Its value |

## The rows the loader reads

| `config_key` | Read by | Meaning |
|---|---|---|
| `base_currency` | `Data Table - Get Base Currency Config` | The currency every stored rate is quoted against |

## Where the default comes from

`make setup-data-table` creates the table and seeds `base_currency` with `USD`
— or with `LOADER_BASE_CURRENCY` if that variable is set in `.env`. The default
lives there, in provisioning, as data. The loader itself holds no currency of
its own and substitutes nothing: with no usable row, the run fails at stage
`CONFIG` and writes nothing to `currency_rates`. That is deliberate — a
workflow-side fallback would let a mis-provisioned stand quietly load a year of
rates against the wrong base.

Seeding is skipped when a non-blank `base_currency` value already exists, so
re-provisioning an existing stand never overwrites a value an operator changed.

## Changing the base currency

Edit the `base_currency` row in the n8n UI (**Data tables → config**). The next
loader run picks it up; no workflow edit, no re-export, no re-import.

Rates already stored under the previous base stay in `currency_rates` — they
carry their own `base_currency`, and the chat agent's tool selects the newest
base and ignores rows quoted against a superseded one, so the table can be
migrated by simply letting the loader run.
