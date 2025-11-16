.PHONY: help dev stop clean install migrate seed test lint build docker-build docker-up docker-down logs

# Default target
.DEFAULT_GOAL := help

# Colors for output
CYAN := \033[0;36m
RESET := \033[0m

## help: Affiche cette aide
help:
	@echo "$(CYAN)Pixora - Commandes disponibles:$(RESET)"
	@sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' | sed -e 's/^/ /'

## dev: Démarre tous les services en mode développement
dev:
	@echo "$(CYAN)Démarrage des services...$(RESET)"
	docker-compose up -d postgres redis minio
	@sleep 3
	@echo "$(CYAN)Démarrage de l'application...$(RESET)"
	npm run dev

## stop: Arrête tous les services
stop:
	@echo "$(CYAN)Arrêt des services...$(RESET)"
	docker-compose down
	@pkill -f "npm run dev" || true

## clean: Supprime volumes Docker et node_modules
clean: stop
	@echo "$(CYAN)Nettoyage...$(RESET)"
	docker-compose down -v
	rm -rf node_modules backend/node_modules frontend/node_modules y-websocket-server/node_modules ai-service/node_modules
	rm -rf backend/dist frontend/.next

## install: Installe toutes les dépendances npm
install:
	@echo "$(CYAN)Installation des dépendances...$(RESET)"
	npm install

## migrate: Exécute les migrations de base de données
migrate:
	@echo "$(CYAN)Exécution des migrations...$(RESET)"
	cd backend && npm run migration:run

## migrate-create: Crée une nouvelle migration (usage: make migrate-create NAME=AddUserTable)
migrate-create:
	@if [ -z "$(NAME)" ]; then \
		echo "Erreur: NAME requis. Usage: make migrate-create NAME=AddUserTable"; \
		exit 1; \
	fi
	cd backend && npm run migration:create -- $(NAME)

## migrate-revert: Annule la dernière migration
migrate-revert:
	@echo "$(CYAN)Annulation de la dernière migration...$(RESET)"
	cd backend && npm run migration:revert

## seed: Remplit la base de données avec des données de test
seed:
	@echo "$(CYAN)Seeding de la base de données...$(RESET)"
	cd backend && npm run seed

## test: Lance tous les tests
test:
	@echo "$(CYAN)Lancement des tests...$(RESET)"
	npm run test

## test-e2e: Lance les tests end-to-end
test-e2e:
	@echo "$(CYAN)Lancement des tests E2E...$(RESET)"
	docker-compose -f docker-compose.test.yml up -d
	@sleep 5
	cd frontend && npm run test:e2e
	docker-compose -f docker-compose.test.yml down

## lint: Lint le code
lint:
	@echo "$(CYAN)Linting...$(RESET)"
	npm run lint

## lint-fix: Lint et corrige automatiquement
lint-fix:
	@echo "$(CYAN)Linting avec auto-fix...$(RESET)"
	npm run lint:fix

## format: Formate le code avec Prettier
format:
	@echo "$(CYAN)Formatage du code...$(RESET)"
	npm run format

## format-check: Vérifie le formatage
format-check:
	@echo "$(CYAN)Vérification du formatage...$(RESET)"
	npm run format:check

## typecheck: Vérifie les types TypeScript
typecheck:
	@echo "$(CYAN)Vérification des types...$(RESET)"
	npm run typecheck

## build: Build l'application pour production
build:
	@echo "$(CYAN)Build de l'application...$(RESET)"
	npm run build

## docker-build: Build les images Docker
docker-build:
	@echo "$(CYAN)Build des images Docker...$(RESET)"
	docker-compose build

## docker-up: Démarre tous les services Docker
docker-up:
	@echo "$(CYAN)Démarrage de Docker Compose...$(RESET)"
	docker-compose up -d

## docker-down: Arrête Docker Compose
docker-down:
	@echo "$(CYAN)Arrêt de Docker Compose...$(RESET)"
	docker-compose down

## docker-logs: Affiche les logs des services Docker
docker-logs:
	docker-compose logs -f

## docker-ps: Liste les containers Docker
docker-ps:
	docker-compose ps

## db-reset: Reset complet de la base de données
db-reset: stop
	@echo "$(CYAN)Reset de la base de données...$(RESET)"
	docker-compose down -v postgres
	docker-compose up -d postgres
	@sleep 5
	$(MAKE) migrate
	$(MAKE) seed

## db-shell: Ouvre un shell PostgreSQL
db-shell:
	docker-compose exec postgres psql -U pixora -d pixora

## redis-cli: Ouvre Redis CLI
redis-cli:
	docker-compose exec redis redis-cli

## logs-backend: Affiche les logs du backend
logs-backend:
	docker-compose logs -f backend

## logs-frontend: Affiche les logs du frontend
logs-frontend:
	docker-compose logs -f frontend

## logs-ws: Affiche les logs du WebSocket server
logs-ws:
	docker-compose logs -f y-websocket

## logs-ai: Affiche les logs du service AI
logs-ai:
	docker-compose logs -f ai-service

## setup: Configuration initiale complète du projet
setup:
	@echo "$(CYAN)Configuration initiale de Pixora...$(RESET)"
	cp .env.example .env
	cp backend/.env.example backend/.env
	cp frontend/.env.example frontend/.env.local
	@echo "$(CYAN)Installation des dépendances...$(RESET)"
	npm install
	@echo "$(CYAN)Démarrage des services...$(RESET)"
	docker-compose up -d postgres redis minio
	@sleep 5
	@echo "$(CYAN)Création de la base de données...$(RESET)"
	$(MAKE) migrate
	$(MAKE) seed
	@echo "$(CYAN)Setup terminé! Lancez 'make dev' pour démarrer l'application.$(RESET)"

## ci: Commande pour CI (lint, test, build)
ci: lint typecheck test build
	@echo "$(CYAN)CI passé avec succès!$(RESET)"

## backup-db: Backup de la base de données
backup-db:
	@echo "$(CYAN)Backup de la base de données...$(RESET)"
	@mkdir -p backups
	docker-compose exec -T postgres pg_dump -U pixora pixora > backups/pixora_$(shell date +%Y%m%d_%H%M%S).sql
	@echo "$(CYAN)Backup créé dans backups/$(RESET)"

## restore-db: Restore de la base de données (usage: make restore-db FILE=backups/pixora_20240101_120000.sql)
restore-db:
	@if [ -z "$(FILE)" ]; then \
		echo "Erreur: FILE requis. Usage: make restore-db FILE=backups/pixora_20240101_120000.sql"; \
		exit 1; \
	fi
	@echo "$(CYAN)Restore de la base de données...$(RESET)"
	cat $(FILE) | docker-compose exec -T postgres psql -U pixora pixora
