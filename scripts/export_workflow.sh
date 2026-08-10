#!/usr/bin/env bash
# Export a workflow from the running Docker n8n container back into workflows/.
#
# This is the inverse of scripts/import_workflow.sh and the tooling behind the
# "Export discipline" rule in root CLAUDE.md: workflows/*.json is the source of
# truth for review, so an edit made in the n8n editor is not finished until it
# has been exported back to the matching file.
#
# Usage:
#   scripts/export_workflow.sh <workflow-id> <file-in-workflows-dir>
# Example:
#   scripts/export_workflow.sh iBdFv2bTfVR7chbE 1-currency-rate-loader.json
#
# The workflow id is required rather than inferred: export is addressed by id,
# the repo names files by number and slug, and guessing the mapping between them
# is exactly the kind of silent mistake this script exists to prevent.
#
# Scope: the Docker stand only. The n8n Cloud dev stand has no CLI, so it cannot
# be reached from a shell script; pull it through the n8n MCP instead (see
# docs/operations.md).
#
# Like import_workflow.sh, this never reads .env and never handles credential
# values — workflow JSON holds credential name/id references only.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <workflow-id> <file-in-workflows-dir>" >&2
  echo "Example: $0 iBdFv2bTfVR7chbE 1-currency-rate-loader.json" >&2
  exit 1
fi

WORKFLOW_ID="$1"
FILE="$2"
HOST_PATH="$REPO_ROOT/workflows/$FILE"
# workflows/ is bind-mounted at /home/node/.n8n/workflows (docker-compose.yml),
# so a file the container writes there appears on the host immediately — the
# same shortcut import_workflow.sh uses, in reverse.
CONTAINER_PATH="/home/node/.n8n/workflows/$FILE"

cd "$REPO_ROOT"

if ! docker compose ps --status running --services 2>/dev/null | grep -qx n8n; then
  echo "Error: the n8n container is not running." >&2
  echo "Start it with 'make up' and retry." >&2
  exit 1
fi

# The CLI exits non-zero and writes nothing for an unknown id; surface that as a
# readable message rather than a bare exit code.
if ! docker compose exec -T n8n n8n export:workflow \
      --id="$WORKFLOW_ID" --output="$CONTAINER_PATH" >/dev/null 2>&1; then
  echo "Error: could not export workflow id '$WORKFLOW_ID'." >&2
  echo "Check the id exists on this stand: docker compose exec n8n n8n list:workflow" >&2
  exit 1
fi

if [[ ! -f "$HOST_PATH" ]]; then
  echo "Error: export reported success but '$HOST_PATH' was not written." >&2
  echo "Verify the workflows/ bind mount is present in docker-compose.yml." >&2
  exit 1
fi

# Normalise formatting so a later diff shows semantic change only. Without this
# the CLI's own layout would churn the diff on every export.
python3 - "$HOST_PATH" <<'PY'
import json, sys
path = sys.argv[1]
with open(path, encoding="utf-8") as fh:
    data = json.load(fh)
# export:workflow --id wraps a single workflow in a list on some n8n versions.
if isinstance(data, list):
    if len(data) != 1:
        sys.exit(f"expected exactly one workflow in {path}, got {len(data)}")
    data = data[0]
with open(path, "w", encoding="utf-8") as fh:
    json.dump(data, fh, indent=2, ensure_ascii=False)
    fh.write("\n")
PY

echo "Exported workflow '$WORKFLOW_ID' -> workflows/$FILE"
