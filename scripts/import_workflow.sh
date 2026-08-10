#!/usr/bin/env bash
# Import a workflow JSON file from workflows/ into the running Docker n8n
# container via the n8n CLI. The `workflows/` directory is bind-mounted into
# the container at /home/node/.n8n/workflows (see docker-compose.yml), so no
# docker cp step is needed — we just point the CLI at the same file container-side.
#
# Usage:
#   scripts/import_workflow.sh <file-in-workflows-dir>
# Example:
#   scripts/import_workflow.sh 1-currency-rate-loader.json
#
# This script never reads .env or handles credential values: workflow JSON
# only ever holds credential name/id references, never secret values, so
# import never needs a secret to succeed.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <file-in-workflows-dir>" >&2
  echo "Example: $0 1-currency-rate-loader.json" >&2
  exit 1
fi

FILE="$1"
HOST_PATH="$REPO_ROOT/workflows/$FILE"

if [[ ! -f "$HOST_PATH" ]]; then
  echo "Error: '$HOST_PATH' does not exist." >&2
  echo "Expected a filename relative to the workflows/ directory, e.g. 1-currency-rate-loader.json" >&2
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
exec docker compose exec n8n n8n import:workflow --input="$CONTAINER_PATH"
