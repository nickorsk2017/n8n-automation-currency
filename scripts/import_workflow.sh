#!/usr/bin/env bash
# Import a workflow JSON file from workflows/ into the running Docker n8n
# container via the n8n CLI. The `workflows/` directory is bind-mounted into
# the container at /home/node/.n8n/workflows (see docker-compose.yml), so no
# docker cp step is needed — we just point the CLI at the same file container-side.
#
# Usage:
#   scripts/import_workflow.sh <file-in-workflows-dir>
# Example:
#   scripts/import_workflow.sh currency-rate-loader.json
#
# This script never reads or handles credential secret values: workflow JSON
# only ever holds credential name/id references, never secret values, so
# import never needs a secret to succeed. It does read N8N_API_URL/N8N_API_KEY
# from the environment (the Makefile target sources .env before calling this
# script, matching scripts/create_data_table.sh) — that's an admin API key
# for this n8n instance, not a workflow secret, needed only for the
# post-import activation call below.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <file-in-workflows-dir>" >&2
  echo "Example: $0 currency-rate-loader.json" >&2
  exit 1
fi

: "${N8N_API_URL:?N8N_API_URL is not set. Copy .env.example to .env and fill it in, or export it manually.}"
: "${N8N_API_KEY:?N8N_API_KEY is not set. Create one in n8n: Settings -> API -> Create API key, then add it to .env.}"

FILE="$1"
HOST_PATH="$REPO_ROOT/workflows/$FILE"

if [[ ! -f "$HOST_PATH" ]]; then
  echo "Error: '$HOST_PATH' does not exist." >&2
  echo "Expected a filename relative to the workflows/ directory, e.g. currency-rate-loader.json" >&2
  exit 1
fi

# n8n's `import:workflow` CLI imports/upserts by the workflow's own top-level
# `id` field rather than generating one — a file without `id` fails deep
# inside the container with an opaque `SQLITE_CONSTRAINT: NOT NULL
# constraint failed: workflow_entity.id`. Catch that here with a clear
# message instead.
if ! python3 -c "import json,sys; sys.exit(0 if 'id' in json.load(open(sys.argv[1])) else 1)" "$HOST_PATH"; then
  echo "Error: '$HOST_PATH' has no top-level \"id\" field." >&2
  echo "n8n's import:workflow CLI requires a stable id to upsert by; without one the import fails with SQLITE_CONSTRAINT: NOT NULL constraint failed: workflow_entity.id." >&2
  echo "Add a unique id (e.g. a 16-char alphanumeric string) to the JSON file and re-run." >&2
  exit 1
fi

CONTAINER_PATH="/home/node/.n8n/workflows/$FILE"

cd "$REPO_ROOT"
if ! docker compose exec n8n n8n import:workflow --input="$CONTAINER_PATH"; then
  echo "Error: 'n8n import:workflow' failed for '$FILE'. Is the Docker stand running? Try 'make up' first." >&2
  exit 1
fi

# The CLI import above does not honor an `active` field in the JSON — a
# workflow always lands inactive regardless of what the file says, which
# silently breaks anything that depends on the workflow actually running
# (a Schedule Trigger that never fires, a self-referencing tool call that
# fails with "Workflow is not active"). Activate explicitly when the file
# says to, using the workflow's own id (already required to exist by the
# precondition check above).
#
# Activation goes through the Public API's dedicated action endpoint
# (POST /workflows/:id/activate), not the `n8n update:workflow` CLI command
# (deprecated — n8n prints a warning, a future version may remove it
# outright) and not a PATCH with an {"active": true} body (returns HTTP 405
# "PATCH method not allowed" on this API version — activate/deactivate are
# modelled as separate actions, not a field on a general update, matching
# how n8n's own "n8n" node exposes them as distinct operations).
WORKFLOW_ID="$(python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['id'])" "$HOST_PATH")"
IS_ACTIVE="$(python3 -c "import json,sys; print('true' if json.load(open(sys.argv[1])).get('active') else 'false')" "$HOST_PATH")"

if [[ "$IS_ACTIVE" == "true" ]]; then
  API_BASE="${N8N_API_URL%/}/api/v1"
  ACTIVATE_RESPONSE=$(curl -sS -w '\n%{http_code}' \
    -X POST "$API_BASE/workflows/$WORKFLOW_ID/activate" \
    -H "X-N8N-API-KEY: $N8N_API_KEY")
  ACTIVATE_STATUS="${ACTIVATE_RESPONSE##*$'\n'}"
  ACTIVATE_BODY="${ACTIVATE_RESPONSE%$'\n'"$ACTIVATE_STATUS"}"

  if [[ "$ACTIVATE_STATUS" == "401" ]]; then
    echo "Error: n8n rejected the API key (401 Unauthorized) while activating '$WORKFLOW_ID'." >&2
    echo "Check N8N_API_KEY in .env matches a key created under Settings -> API." >&2
    exit 1
  fi

  if [[ "$ACTIVATE_STATUS" != 2* ]]; then
    echo "Error: POST $API_BASE/workflows/$WORKFLOW_ID/activate failed (HTTP $ACTIVATE_STATUS)." >&2
    echo "$ACTIVATE_BODY" >&2
    echo "Check {N8N_API_URL}/api/v1/docs on the running instance for this n8n version's actual activate endpoint if this persists." >&2
    exit 1
  fi
fi
