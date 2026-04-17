# ============================================================
# Online Marketplace Database — Makefile
# ============================================================

DB_CONTAINER = marketplace_db
DB_NAME      = marketplace
DB_USER      = student

GREEN  = \033[0;32m
YELLOW = \033[0;33m
CYAN   = \033[0;36m
NC     = \033[0m

.PHONY: help up down restart psql init queries clean status logs web-logs

help: ## Показать справку
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-14s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "  $(CYAN)Web UI:$(NC)  http://localhost:8080"
	@echo "  $(CYAN)DB:$(NC)      localhost:5432  (student / student123)"
	@echo ""

up: ## Запустить PostgreSQL + Web UI
	docker compose up -d --build

down: ## Остановить все контейнеры
	docker compose down

restart: down up ## Перезапустить всё

clean: ## Остановить и удалить все данные
	docker compose down -v --rmi local

psql: ## Открыть интерактивную консоль psql
	docker exec -it $(DB_CONTAINER) psql -U $(DB_USER) -d $(DB_NAME)

status: ## Проверить статус контейнеров
	@docker compose ps

logs: ## Показать логи PostgreSQL
	docker compose logs -f postgres

web-logs: ## Показать логи Web UI
	docker compose logs -f web

init: ## Пересоздать схему и загрузить данные
	docker exec -i $(DB_CONTAINER) psql -U $(DB_USER) -d $(DB_NAME) < schema.sql
	docker exec -i $(DB_CONTAINER) psql -U $(DB_USER) -d $(DB_NAME) < seed_data.sql

queries: ## Выполнить все запросы из queries.sql
	docker exec -i $(DB_CONTAINER) psql -U $(DB_USER) -d $(DB_NAME) < queries.sql

query: ## Выполнить один запрос: make query SQL="SELECT * FROM players"
	@docker exec -i $(DB_CONTAINER) psql -U $(DB_USER) -d $(DB_NAME) -c "$(SQL)"

examples: ## Запустить интерактивную демонстрацию в терминале
	@bash run_examples.sh
