#!/usr/bin/env bash
# Activate (publish) a workflow already imported into the running n8n
# instance, if its JSON says `"active": true`. A no-op (exit 0) for a file
# with `active` false/absent — this script is safe to call unconditionally
# from a loop over every workflow file.
#
# This logic used to live inline in scripts/import_workflow.sh; it was split
# out so `make import-all` can import every workflow file first (in any
# order) and only then activate them in dependency order (see
# scripts/order_workflows.py) — n8n refuses to publish a workflow that
# references a sub-workflow which is not itself published yet.
#
# Usage:
#   scripts/activate_workflow.sh <file-in-workflows-dir>
# Example:
#   scripts/activate_workflow.sh ai-chat-currency-agent.json
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <file-in-workflows-dir>" >&2
  echo "Example: $0 ai-chat-currency-agent.json" >&2
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

if ! python3 -c "import json,sys; sys.exit(0 if 'id' in json.load(open(sys.argv[1])) else 1)" "$HOST_PATH"; then
  echo "Error: '$HOST_PATH' has no top-level \"id\" field." >&2
  exit 1
fi

# The CLI import (scripts/import_workflow.sh) never honors an `active` field
# in the JSON — a workflow always lands inactive regardless of what the file
# says, which silently breaks anything that depends on the workflow actually
# running (a Schedule Trigger that never fires, a self-referencing tool call
# that fails with "Workflow is not active"). Activate explicitly when the
# file says to, using the workflow's own id.
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

if [[ "$IS_ACTIVE" != "true" ]]; then
  exit 0
fi

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
