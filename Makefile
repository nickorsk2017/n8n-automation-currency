.PHONY: help up down restart logs ps clean setup-data-table import-credentials setup import import-all export drift

# --- General ---------------------------------------------------------------

help: ## Show this help
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*##"}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

# Guard: scripts/*.sh are tracked as mode 100755 in git, but a local checkout
# or copy can still lose the executable bit. Auto-repair it; if that's not
# possible (missing file, read-only mount), fail loud with a greppable marker
# instead of the OS's bare "Permission denied". Exit 126 matches the shell's
# own convention for "found but not executable" (see bash(1) EXIT STATUS).
define ensure_executable
	if [ ! -f "$(1)" ]; then \
		echo "ERR_SCRIPT_NOT_EXECUTABLE: '$(1)' not found" >&2; \
		exit 126; \
	fi; \
	if [ ! -x "$(1)" ]; then \
		if chmod +x "$(1)" 2>/dev/null; then \
			echo "note: restored exec bit on $(1) (tracked as executable in git; local checkout had lost it)" >&2; \
		else \
			echo "ERR_SCRIPT_NOT_EXECUTABLE: '$(1)' is not executable and chmod failed (read-only mount?). Fix: chmod +x $(1)" >&2; \
			exit 126; \
		fi; \
	fi
endef

# Guard: targets addressed at a single workflow take ID / FILE on the command
# line. Without them the recipe still runs, and `$(FILE)` expanding to nothing
# turns `cp workflows/$(FILE)` into a command aimed at the whole directory. Fail
# before the first command of the recipe, with a greppable marker and the usage
# line, rather than after something has already been copied or moved. Exit 2 =
# "invoked wrong", distinct from 126 = "script not executable" above.
define require_var
	if [ -z "$(2)" ]; then \
		echo "ERR_MISSING_VAR: $(1) is required. Usage: $(3)" >&2; \
		exit 2; \
	fi
endef

# --- Stack lifecycle (local Docker stand) -----------------------------------

up: ## Start n8n in the background
	docker compose up -d

down: ## Stop and remove the containers
	docker compose down

restart: ## Restart the running stack
	docker compose restart

logs: ## Follow n8n container logs
	docker compose logs -f n8n

ps: ## Show container status
	docker compose ps

clean: ## Wipe the local Docker stand completely - containers + all data (DESTRUCTIVE, asks to confirm; usage: make clean [FORCE=1])
	@$(call ensure_executable,scripts/clean_docker_stand.sh)
	scripts/clean_docker_stand.sh

# --- Workflow sync (repo <-> running instance) ------------------------------

# The config table is where the loader's base currency lives. To change it on a
# running stand: n8n UI -> Data tables -> config -> edit the base_currency row.
# The next loader run uses it; no workflow edit, export or re-import. Re-running
# this target never overwrites a value already set there. A run that fails with
# failure_stage=CONFIG means that row is missing or blank on this stand.
setup-data-table: ## Create the currency_rates, error_log and config Data Tables via the n8n API if they don't exist yet, and seed the default base currency (idempotent; needs N8N_API_URL/N8N_API_KEY in .env)
	@$(call ensure_executable,scripts/create_data_table.sh)
	@set -a; . ./.env; set +a; scripts/create_data_table.sh

import-credentials: ## Provision the freecurrencyapi + OpenAI credentials from .env via the n8n CLI (idempotent; needs FREECURRENCYAPI_KEY/LLM_OPENAI_KEY in .env; no manual n8n UI step)
	@$(call ensure_executable,scripts/import_credentials.sh)
	@set -a; . ./.env; set +a; scripts/import_credentials.sh

setup: setup-data-table import-credentials ## Provision the Docker stand from .env alone: currency_rates + error_log + config Data Tables (config seeded with LOADER_BASE_CURRENCY, default USD) + freecurrencyapi + OpenAI credentials

import: ## Import a workflow JSON into the running n8n container and activate it if the file says active:true (usage: make import FILE=currency-rate-loader.json; needs N8N_API_URL/N8N_API_KEY in .env)
	@$(call require_var,FILE,$(FILE),make import FILE=currency-rate-loader.json)
	@$(call ensure_executable,scripts/import_workflow.sh)
	@$(call ensure_executable,scripts/activate_workflow.sh)
	@set -a; . ./.env; set +a; \
	scripts/import_workflow.sh $(FILE) && scripts/activate_workflow.sh $(FILE)

import-all: ## Import every workflow JSON in workflows/ into the running n8n container, then activate in dependency order (needs N8N_API_URL/N8N_API_KEY in .env)
	@$(call ensure_executable,scripts/import_workflow.sh)
	@$(call ensure_executable,scripts/activate_workflow.sh)
	@set -a; . ./.env; set +a; \
	for f in workflows/*.json; do \
		case "$$(basename $$f)" in \
			n8n-credentials-import.json) continue ;; \
		esac; \
		echo "==> $$f"; \
		scripts/import_workflow.sh $$(basename $$f) || exit 1; \
	done; \
	echo "==> computing activation order"; \
	order="$$(python3 scripts/order_workflows.py)" || exit 1; \
	for f in $$order; do \
		echo "==> activating $$f"; \
		scripts/activate_workflow.sh $$f || exit 1; \
	done

export: ## Export a workflow from the n8n container back into workflows/ (usage: make export ID=<WORKFLOW_ID> FILE=currency-rate-loader.json)
	@$(call require_var,ID,$(ID),make export ID=<WORKFLOW_ID> FILE=currency-rate-loader.json)
	@$(call require_var,FILE,$(FILE),make export ID=<WORKFLOW_ID> FILE=currency-rate-loader.json)
	@$(call ensure_executable,scripts/export_workflow.sh)
	scripts/export_workflow.sh $(ID) $(FILE)

drift: ## Check workflows/<FILE> still matches the instance (usage: make drift ID=<WORKFLOW_ID> FILE=currency-rate-loader.json)
	@$(call require_var,ID,$(ID),make drift ID=<WORKFLOW_ID> FILE=currency-rate-loader.json)
	@$(call require_var,FILE,$(FILE),make drift ID=<WORKFLOW_ID> FILE=currency-rate-loader.json)
	@$(call ensure_executable,scripts/export_workflow.sh)
	@set -e; tmp=$$(mktemp -d); trap 'rm -rf $$tmp' EXIT; \
	cp workflows/$(FILE) $$tmp/repo.json && \
	scripts/export_workflow.sh $(ID) $(FILE) >/dev/null && \
	cp workflows/$(FILE) $$tmp/instance.json && \
	cp $$tmp/repo.json workflows/$(FILE) && \
	scripts/check_workflow_drift.py workflows/$(FILE) $$tmp/instance.json
