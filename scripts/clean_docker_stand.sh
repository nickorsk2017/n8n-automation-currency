#!/usr/bin/env bash
# Fully wipe the local Docker n8n stand: stop the stack and delete the
# `n8n_data` volume defined in docker-compose.yml, so every workflow,
# credential, and execution record on that stand is gone and the next
# `make up` starts from a clean n8n instance.
#
# Usage:
#   scripts/clean_docker_stand.sh           # prompts for confirmation
#   scripts/clean_docker_stand.sh -y        # skip the prompt
#   FORCE=1 scripts/clean_docker_stand.sh   # skip the prompt (scripted use)
#
# Scope: the Docker stand only. This does NOT touch:
#   - workflows/*.json in this repository (the source of truth for review),
#   - the n8n Cloud dev stand (it has no CLI reachable from a shell script;
#     see docs/architecture.md for the two-stand model).
# After this runs, `make up && make import-all` restores the two workflows
# on a fresh, empty instance.
#
# This is destructive and irreversible for anything stored only in the
# Docker stand (manually created credentials, test executions, ad-hoc
# workflows never exported to the repo) — hence the confirmation gate.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

FORCE="${FORCE:-0}"
if [[ "${1:-}" == "-y" || "${1:-}" == "--force" ]]; then
  FORCE=1
fi

if [[ "$FORCE" != "1" ]]; then
  echo "This will permanently delete the local Docker n8n stand:" >&2
  echo "  - all workflows, credentials, and execution history stored there" >&2
  echo "  - the 'n8n_data' Docker volume (docker-compose.yml)" >&2
  echo "" >&2
  echo "workflows/*.json in this repository is NOT affected." >&2
  echo "" >&2
  read -r -p "Type 'yes' to permanently delete the local Docker stand: " reply
  if [[ "$reply" != "yes" ]]; then
    echo "Aborted. Nothing was deleted." >&2
    exit 1
  fi
fi

if ! docker compose down -v; then
  echo "Error: 'docker compose down -v' failed — is Docker running?" >&2
  exit 1
fi

echo "Local Docker n8n stand wiped. workflows/*.json in the repo is untouched." >&2
echo "Run 'make up && make import-all' to restore the workflows on a fresh instance." >&2
