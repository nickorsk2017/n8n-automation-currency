#!/usr/bin/env bash
# Idempotently create the `currency_rates` Data Table on a running local n8n
# Docker stand, via n8n's Public API (/api/v1/data-tables). Both workflows
# depend on this table already existing by name: the Data Table node picks
# an existing table from a dropdown, it does not create one on first run.
#
# Column list here is a literal transcription of the schema documented in
# docs/workflows/rate-loader/data-table-schema.md — that doc is the source
# of truth; if the schema changes, update both together.
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

TABLE_NAME="currency_rates"

: "${N8N_API_URL:?N8N_API_URL is not set. Copy .env.example to .env and fill it in, or export it manually.}"
: "${N8N_API_KEY:?N8N_API_KEY is not set. Create one in n8n: Settings -> API -> Create API key, then add it to .env.}"

API_BASE="${N8N_API_URL%/}/api/v1"

# --- 1. Check whether a table with this name already exists (idempotency) --

EXISTING_FILTER=$(printf '{"name":"%s"}' "$TABLE_NAME")
EXISTING_RESPONSE=$(curl -sS -w '\n%{http_code}' \
  -H "X-N8N-API-KEY: $N8N_API_KEY" \
  -G "$API_BASE/data-tables" \
  --data-urlencode "filter=$EXISTING_FILTER")

EXISTING_STATUS="${EXISTING_RESPONSE##*$'\n'}"
EXISTING_BODY="${EXISTING_RESPONSE%$'\n'"$EXISTING_STATUS"}"

if [[ "$EXISTING_STATUS" == "401" ]]; then
  echo "Error: n8n rejected the API key (401 Unauthorized)." >&2
  echo "Check N8N_API_KEY in .env matches a key created under Settings -> API." >&2
  exit 1
fi

if [[ "$EXISTING_STATUS" != "200" ]]; then
  echo "Error: GET $API_BASE/data-tables failed (HTTP $EXISTING_STATUS)." >&2
  echo "$EXISTING_BODY" >&2
  exit 1
fi

ALREADY_EXISTS=$(python3 -c "
import json, sys
data = json.load(sys.stdin)
names = [t.get('name') for t in data.get('data', [])]
print('yes' if '$TABLE_NAME' in names else 'no')
" <<< "$EXISTING_BODY")

if [[ "$ALREADY_EXISTS" == "yes" ]]; then
  echo "Data table '$TABLE_NAME' already exists — nothing to do."
  exit 0
fi

# --- 2. Create the table -----------------------------------------------

CREATE_BODY=$(cat << JSON
{
  "name": "$TABLE_NAME",
  "columns": [
    { "name": "base_currency",   "type": "string" },
    { "name": "target_currency", "type": "string" },
    { "name": "rate",            "type": "number" },
    { "name": "fetched_at",      "type": "string" }
  ]
}
JSON
)

CREATE_RESPONSE=$(curl -sS -w '\n%{http_code}' \
  -X POST "$API_BASE/data-tables" \
  -H "X-N8N-API-KEY: $N8N_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$CREATE_BODY")

CREATE_STATUS="${CREATE_RESPONSE##*$'\n'}"
CREATE_RESP_BODY="${CREATE_RESPONSE%$'\n'"$CREATE_STATUS"}"

if [[ "$CREATE_STATUS" == "401" ]]; then
  echo "Error: n8n rejected the API key (401 Unauthorized)." >&2
  echo "Check N8N_API_KEY in .env matches a key created under Settings -> API." >&2
  exit 1
fi

if [[ "$CREATE_STATUS" == "409" ]]; then
  echo "Data table '$TABLE_NAME' already exists (race with a concurrent create) — nothing to do."
  exit 0
fi

if [[ "$CREATE_STATUS" != "201" ]]; then
  echo "Error: POST $API_BASE/data-tables failed (HTTP $CREATE_STATUS)." >&2
  echo "$CREATE_RESP_BODY" >&2
  exit 1
fi

echo "Created data table '$TABLE_NAME'."
