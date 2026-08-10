#!/usr/bin/env bash
# Provision the credentials Workflow 1 and Workflow 2 depend on into the
# Docker n8n instance's credential store via the n8n CLI, from .env — no
# REST API call (no GET or POST to /credentials), no manual entry in the
# n8n Credentials UI.
#
# Each credential's id below is fixed and must match the corresponding
# node's `credentials` block in the matching workflow JSON:
#   - freecurrencyapi -> workflows/currency-rate-loader.json,
#     "HTTP Request - Fetch Latest Rates" (credentials.httpQueryAuth.id)
#   - OpenAI            -> workflows/ai-chat-currency-agent.json,
#     "OpenAI Chat Model - GPT" (credentials.openAiApi.id)
# `n8n import:credentials` upserts by id — the same idempotency guarantee
# scripts/import_workflow.sh already relies on for `n8n import:workflow` —
# so re-running this script updates the existing credentials in place
# rather than duplicating them, and the workflow JSON references never go
# stale.
#
# Usage:
#   scripts/import_credentials.sh
# Requires FREECURRENCYAPI_KEY and LLM_OPENAI_KEY in the environment (the
# Makefile target sources .env before calling this script, matching
# setup-data-table).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Fixed ids — must match the corresponding node's credential id in the
# workflow JSON files listed above. Changing one here without updating that
# file breaks the node's credential reference.
FREECURRENCYAPI_CREDENTIAL_ID="fcaHttpQueryAuth"
LLM_OPENAI_CREDENTIAL_ID="llmOpenAiApiCred"

: "${FREECURRENCYAPI_KEY:?FREECURRENCYAPI_KEY is not set. Copy .env.example to .env and fill it in, or export it manually.}"
: "${LLM_OPENAI_KEY:?LLM_OPENAI_KEY is not set. Copy .env.example to .env and fill it in, or export it manually.}"

if [[ "$FREECURRENCYAPI_KEY" == "your_freecurrencyapi_key_here" ]]; then
  echo "Error: FREECURRENCYAPI_KEY in .env is still the placeholder value." >&2
  echo "Get a free-tier key at https://freecurrencyapi.com and put it in .env." >&2
  exit 1
fi

if [[ "$LLM_OPENAI_KEY" == "your_llm_provider_key_here" ]]; then
  echo "Error: LLM_OPENAI_KEY in .env is still the placeholder value." >&2
  echo "Put a real OpenAI API key in .env — the Docker stand has no managed" >&2
  echo "free-credits credential (that's a Cloud-account-linked offering, not" >&2
  echo "available on a bare self-hosted instance)." >&2
  exit 1
fi

# workflows/ is bind-mounted into the container at /home/node/.n8n/workflows
# (see docker-compose.yml) — same trick import_workflow.sh relies on. The
# rendered file's name matches the existing .gitignore rule
# (n8n-credentials*.json) as defence in depth beyond the trap below.
TMP_FILE="$REPO_ROOT/workflows/n8n-credentials-import.json"
CONTAINER_PATH="/home/node/.n8n/workflows/n8n-credentials-import.json"

cleanup() {
  rm -f "$TMP_FILE"
}
trap cleanup EXIT

# Secrets passed via environment, not argv, so they never appear in a
# process listing (ps/top) while this runs.
FCA_KEY="$FREECURRENCYAPI_KEY" LLM_KEY="$LLM_OPENAI_KEY" python3 - \
  "$TMP_FILE" "$FREECURRENCYAPI_CREDENTIAL_ID" "$LLM_OPENAI_CREDENTIAL_ID" << 'PY'
import json, os, sys

path, fca_id, llm_id = sys.argv[1], sys.argv[2], sys.argv[3]
fca_key = os.environ["FCA_KEY"]
llm_key = os.environ["LLM_KEY"]

credentials = [
    {
        "id": fca_id,
        "name": "freecurrencyapi",
        "type": "httpQueryAuth",
        "data": {"name": "apikey", "value": fca_key},
    },
    {
        "id": llm_id,
        "name": "OpenAI",
        "type": "openAiApi",
        "data": {"apiKey": llm_key},
    },
]

with open(path, "w") as f:
    json.dump(credentials, f, indent=2)
PY

if [[ ! -f "$TMP_FILE" ]]; then
  echo "Error: failed to render $TMP_FILE." >&2
  exit 1
fi

cd "$REPO_ROOT"
if ! docker compose exec n8n n8n import:credentials --input="$CONTAINER_PATH"; then
  echo "Error: 'n8n import:credentials' failed. Is the Docker stand running? Try 'make up' first." >&2
  exit 1
fi

echo "Imported credentials 'freecurrencyapi' (id: $FREECURRENCYAPI_CREDENTIAL_ID) and 'OpenAI' (id: $LLM_OPENAI_CREDENTIAL_ID)."
