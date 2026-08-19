# TASK — 2026-08-19-loader-base-currency-from-config
owner: Engineer
immutable: true

## Requirements
- R1: The loader's `base_currency` is configuration data held in an n8n Data Table,
  not a value defined inside the workflow. The `Set - Loader Config` node is removed
  from `workflows/currency-rate-loader.json`.
- R2: Every point in the loader that needs the base currency reads it from that
  config table (directly or from the single node that read it), including the HTTP
  query parameter, the row builder, and the error-record builder — none of which may
  reference `Set - Loader Config` afterwards.
- R3: The effective default is `USD`: a stand provisioned from scratch and run
  without any manual configuration loads USD-based rates, exactly as today.
- R4: The literal `USD` does not appear in `workflows/currency-rate-loader.json`.
  The default lives in whatever provisions the config table, as data.
- R5: The config table is provisioned idempotently by the existing setup path
  (`make setup` / `scripts/create_data_table.sh`), including its default row.
  Re-running provisioning must not overwrite a base currency an operator has
  changed in the table.
- R6: A missing or empty config value fails the run through the loader's existing
  error path rather than silently falling back to a currency chosen by the
  workflow; no partial or wrongly-based data reaches `currency_rates`.

## Acceptance
- A1: `workflows/currency-rate-loader.json` contains no `Set - Loader Config` node,
  no reference to it in any expression or Code node, and no `USD` literal; the
  connection graph is intact (trigger -> config read -> HTTP -> ... unchanged
  downstream).
- A2: A fresh stand provisioned with `make setup` and `make import` runs the loader
  end to end and upserts rows with `base_currency = USD`.
- A3: Changing the base currency in the config table alone (no workflow edit,
  no re-import) changes the base of the next run's fetched rows.
- A4: Re-running `scripts/create_data_table.sh` after such a change leaves the
  operator's value in place.
- A5: With the config row absent or blank, the run ends in the loader's error branch
  with a diagnosable failure stage and writes nothing to `currency_rates`.
- A6: `docs/workflows/rate-loader/` documents the config table (name, columns, the
  default, how to change the base); `docs/` and `README.md` links still resolve and
  no doc still describes `Set - Loader Config`.

## Constraints
- Root CLAUDE.md n8n conventions apply: descriptive typed node names, `notes` on
  non-obvious nodes, built-ins preferred over Code nodes, no secrets in JSON,
  Data Table resource locators referenced by `mode: "name"`.
- Export discipline: the JSON in `workflows/` is the deliverable; any editor change
  is re-exported in this task.
- The chat agent's own base-currency handling (it derives the base from the
  `base_currency` column of `currency_rates`) is out of scope and must not regress.
