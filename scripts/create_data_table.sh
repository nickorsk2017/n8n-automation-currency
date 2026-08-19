#!/usr/bin/env bash
# Idempotently create every Data Table this repo's workflows depend on, on a
# running local n8n Docker stand, via n8n's Public API (/api/v1/data-tables).
# The Data Table node picks an existing table from a dropdown, it does not
# create one on first run, so both workflows need their table(s) provisioned
# before import.
#
# Three tables today:
#   - currency_rates — columns transcribed from
#     docs/workflows/rate-loader/data-table-schema.md
#   - error_log       — columns transcribed from
#     docs/workflows/error-logger/README.md
#   - config          — shared key/value settings read by the workflows at run
#     time; see docs/workflows/rate-loader/config-table.md
# If a schema changes, update both the doc and the matching entry below
# together.
#
# The config table is also seeded here, because the loader deliberately holds no
# base currency of its own: the default lives in this script as data (or in
# LOADER_BASE_CURRENCY), not in the workflow JSON. Seeding is skipped when the
# row already exists, so re-running this script never overwrites a base currency
# an operator has changed in the table.
#
# Usage:
#   scripts/create_data_table.sh
#
# Requires N8N_API_URL and N8N_API_KEY in the environment (the Makefile
# target sources .env before calling this script). Get an API key from the
# running instance: Settings -> API -> Create API key.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

: "${N8N_API_URL:?N8N_API_URL is not set. Copy .env.example to .env and fill it in, or export it manually.}"
: "${N8N_API_KEY:?N8N_API_KEY is not set. Create one in n8n: Settings -> API -> Create API key, then add it to .env.}"

API_BASE="${N8N_API_URL%/}/api/v1"

# create_table_if_missing <table-name> <columns-json>
# <columns-json> is the JSON array value for the API's "columns" field.
create_table_if_missing() {
  local table_name="$1"
  local columns_json="$2"

  # --- 1. Check whether a table with this name already exists (idempotency) --

  local existing_filter existing_response existing_status existing_body already_exists
  existing_filter=$(printf '{"name":"%s"}' "$table_name")
  existing_response=$(curl -sS -w '\n%{http_code}' \
    -H "X-N8N-API-KEY: $N8N_API_KEY" \
    -G "$API_BASE/data-tables" \
    --data-urlencode "filter=$existing_filter")

  existing_status="${existing_response##*$'\n'}"
  existing_body="${existing_response%$'\n'"$existing_status"}"

  if [[ "$existing_status" == "401" ]]; then
    echo "Error: n8n rejected the API key (401 Unauthorized)." >&2
    echo "Check N8N_API_KEY in .env matches a key created under Settings -> API." >&2
    exit 1
  fi

  if [[ "$existing_status" != "200" ]]; then
    echo "Error: GET $API_BASE/data-tables failed (HTTP $existing_status)." >&2
    echo "$existing_body" >&2
    exit 1
  fi

  already_exists=$(python3 -c "
import json, sys
data = json.load(sys.stdin)
names = [t.get('name') for t in data.get('data', [])]
print('yes' if '$table_name' in names else 'no')
" <<< "$existing_body")

  if [[ "$already_exists" == "yes" ]]; then
    echo "Data table '$table_name' already exists — nothing to do."
    return 0
  fi

  # --- 2. Create the table -----------------------------------------------

  local create_body create_response create_status create_resp_body
  create_body=$(cat << JSON
{
  "name": "$table_name",
  "columns": $columns_json
}
JSON
  )

  create_response=$(curl -sS -w '\n%{http_code}' \
    -X POST "$API_BASE/data-tables" \
    -H "X-N8N-API-KEY: $N8N_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$create_body")

  create_status="${create_response##*$'\n'}"
  create_resp_body="${create_response%$'\n'"$create_status"}"

  if [[ "$create_status" == "401" ]]; then
    echo "Error: n8n rejected the API key (401 Unauthorized)." >&2
    echo "Check N8N_API_KEY in .env matches a key created under Settings -> API." >&2
    exit 1
  fi

  if [[ "$create_status" == "409" ]]; then
    echo "Data table '$table_name' already exists (race with a concurrent create) — nothing to do."
    return 0
  fi

  if [[ "$create_status" != "201" ]]; then
    echo "Error: POST $API_BASE/data-tables failed (HTTP $create_status)." >&2
    echo "$create_resp_body" >&2
    exit 1
  fi

  echo "Created data table '$table_name'."
}

# table_id <table-name> — print the id of an existing data table.
table_id() {
  local table_name="$1" filter response status body
  filter=$(printf '{"name":"%s"}' "$table_name")
  response=$(curl -sS -w '\n%{http_code}' \
    -H "X-N8N-API-KEY: $N8N_API_KEY" \
    -G "$API_BASE/data-tables" \
    --data-urlencode "filter=$filter")
  status="${response##*$'\n'}"
  body="${response%$'\n'"$status"}"

  if [[ "$status" != "200" ]]; then
    echo "Error: GET $API_BASE/data-tables failed while resolving '$table_name' (HTTP $status)." >&2
    echo "$body" >&2
    exit 1
  fi

  python3 -c "
import json, sys
tables = [t for t in json.load(sys.stdin).get('data', []) if t.get('name') == '$table_name']
if not tables:
    sys.exit(\"table '$table_name' not found after creation\")
print(tables[0]['id'])
" <<< "$body"
}

# seed_config_if_missing <config-key> <default-value>
# Insert a config row only when no usable value is present. Rows are read in
# full and matched here rather than through the API's row filter, so this stays
# correct regardless of the filter dialect the instance's API version expects —
# the config table holds a handful of rows.
seed_config_if_missing() {
  local config_key="$1" default_value="$2"
  local table id rows_response rows_status rows_body existing insert_body insert_response insert_status insert_resp_body

  table="config"
  id=$(table_id "$table")

  rows_response=$(curl -sS -w '\n%{http_code}' \
    -H "X-N8N-API-KEY: $N8N_API_KEY" \
    -G "$API_BASE/data-tables/$id/rows" \
    --data-urlencode "limit=250")
  rows_status="${rows_response##*$'\n'}"
  rows_body="${rows_response%$'\n'"$rows_status"}"

  if [[ "$rows_status" != "200" ]]; then
    echo "Error: GET $API_BASE/data-tables/$id/rows failed (HTTP $rows_status)." >&2
    echo "$rows_body" >&2
    exit 1
  fi

  existing=$(python3 -c "
import json, sys
rows = json.load(sys.stdin).get('data', [])
values = [r.get('config_value') for r in rows if r.get('config_key') == '$config_key']
usable = [v for v in values if isinstance(v, str) and v.strip()]
print(usable[0] if usable else '')
" <<< "$rows_body")

  if [[ -n "$existing" ]]; then
    echo "Config '$config_key' is already set to '$existing' — leaving it untouched."
    return 0
  fi

  insert_body=$(python3 -c "
import json
print(json.dumps({'data': [{'config_key': '$config_key', 'config_value': '$default_value'}]}))
")

  insert_response=$(curl -sS -w '\n%{http_code}' \
    -X POST "$API_BASE/data-tables/$id/rows" \
    -H "X-N8N-API-KEY: $N8N_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$insert_body")
  insert_status="${insert_response##*$'\n'}"
  insert_resp_body="${insert_response%$'\n'"$insert_status"}"

  if [[ "$insert_status" != "200" && "$insert_status" != "201" ]]; then
    echo "Error: POST $API_BASE/data-tables/$id/rows failed (HTTP $insert_status)." >&2
    echo "$insert_resp_body" >&2
    exit 1
  fi

  echo "Seeded config '$config_key' = '$default_value'."
}

create_table_if_missing "currency_rates" '[
    { "name": "base_currency",   "type": "string" },
    { "name": "target_currency", "type": "string" },
    { "name": "rate",            "type": "number" },
    { "name": "fetched_at",      "type": "string" }
  ]'

create_table_if_missing "error_log" '[
    { "name": "source_workflow", "type": "string" },
    { "name": "context",         "type": "string" },
    { "name": "message",         "type": "string" }
  ]'

create_table_if_missing "config" '[
    { "name": "config_key",   "type": "string" },
    { "name": "config_value", "type": "string" }
  ]'

# The loader reads its base currency from this row and substitutes nothing of
# its own, so a stand with no row here fails its run loudly instead of loading
# rates against a silently assumed currency.
seed_config_if_missing "base_currency" "${LOADER_BASE_CURRENCY:-USD}"
