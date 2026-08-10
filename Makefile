# Currency Converter AI Agent — operations
#
# Operational instructions live here, next to the commands they describe,
# rather than in a separate document that would drift from these targets.
# Conceptual documentation is in docs/.
#
# REQUIREMENTS
#   Docker and Docker Compose. Python 3 (used by the helper scripts).
#   A free freecurrencyapi.com key — the free tier allows 1000 requests a month
#   and the loader uses one a day.
#   An OpenAI key, or n8n's own free AI credits, for the chat model.
#
# FIRST RUN
#   cp .env.example .env     # fill in FREECURRENCYAPI_KEY and LLM_OPENAI_KEY
#   make up                  # n8n at http://localhost:5678
#
#   .env is gitignored and holds only secrets. Non-secret settings that must be
#   identical on every stand — GENERIC_TIMEZONE=UTC and TZ=UTC — live in
#   docker-compose.yml instead, so correct scheduling never depends on a file
#   that is not committed.
#
# CREDENTIALS
#   Neither key is ever written into workflow JSON; exported workflows carry
#   credential name/id references only. Create both in n8n and attach them:
#     freecurrencyapi — Generic Credential Type -> Query Auth, parameter name
#       `apikey`, attached to "HTTP Request - Fetch Latest Rates". A stored
#       credential rather than an $$env expression because n8n Cloud blocks
#       $$env at runtime: the env-var approach works on Docker and silently
#       fails on Cloud.
#     OpenAI — type openAiApi, attached to "OpenAI Chat Model - GPT".
#
# TWO STANDS
#   The import/export/drift targets below reach the Docker stand through the
#   n8n CLI. The n8n Cloud dev stand has no CLI and cannot be reached from a
#   shell script; pull or push it through the n8n MCP connector instead.
#
#   `import` upserts by the workflow's own top-level `id`, so that field must
#   match the workflow it is meant to update. If it does not, the import
#   creates a second workflow rather than updating the first — for the loader,
#   two workflows competing on the same daily schedule.
#
# WHEN THE LOADER RUN IS RED
#   A failed execution means no rates were written that day; this is intended
#   signalling, not a regression. Open the execution and read the output of
#   "Code - Build Error Record": failure_stage says whether the API call failed
#   (HTTP_FETCH), the response was unusable (API_RESPONSE), or the transformed
#   rows failed validation (ROW_VALIDATION). The data table is never partially
#   written, so re-running after a fix needs no cleanup.

.PHONY: help up down restart logs ps import export drift

help: ## Show this help
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*##"}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

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

import: ## Import a workflow JSON into the running n8n container (usage: make import FILE=1-currency-rate-loader.json)
	scripts/import_workflow.sh $(FILE)

export: ## Export a workflow from the n8n container back into workflows/ (usage: make export ID=iBdFv2bTfVR7chbE FILE=1-currency-rate-loader.json)
	scripts/export_workflow.sh $(ID) $(FILE)

drift: ## Check workflows/<FILE> still matches the instance (usage: make drift ID=iBdFv2bTfVR7chbE FILE=1-currency-rate-loader.json)
	@tmp=$$(mktemp -d); \
	cp workflows/$(FILE) $$tmp/repo.json; \
	scripts/export_workflow.sh $(ID) $(FILE) >/dev/null; \
	mv workflows/$(FILE) $$tmp/instance.json; \
	mv $$tmp/repo.json workflows/$(FILE); \
	scripts/check_workflow_drift.py workflows/$(FILE) $$tmp/instance.json; \
	status=$$?; rm -rf $$tmp; exit $$status
