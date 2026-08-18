#!/usr/bin/env bash
# Idempotently create every Data Table this repo's workflows depend on, on a
# running local n8n Docker stand, via n8n's Public API (/api/v1/data-tables).
# The Data Table node picks an existing table from a dropdown, it does not
# create one on first run, so both workflows need their table(s) provisioned
# before import.
#
# Two tables today:
#   - currency_rates — columns transcribed from
#     docs/workflows/rate-loader/data-table-schema.md
#   - error_log       — columns transcribed from
#     docs/workflows/error-logger/README.md
# If a schema changes, update both the doc and the matching entry below
# together.
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
