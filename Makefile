.PHONY: help up down restart logs ps

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
