# **************************************************************************** #
# Makefile                                                                     #
# **************************************************************************** #

# Colors
GREEN	:= \033[0;32m
RED		:= \033[0;31m
BLUE	:= \033[0;34m
YELLOW	:= \033[1;33m
NC		:= \033[0m

# Variables
COMPOSE_FILE	= srcs/docker-compose.yml
PROJECT_NAME	= inception
DATA_PATH		= /home/$(USER)/data

# Services
SERVICES		= nginx mariadb wordpress

# **************************************************************************** #
# Targets                                                                      #
# **************************************************************************** #

.PHONY: all build up down stop start restart clean fclean re logs ps

## Build and start all containers
all: build up

## Build all containers
build:
	@echo "$(BLUE)Building containers...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) build

## Start all containers in detached mode
up:
	@echo "$(GREEN)Starting containers...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) up -d

## Build and start specific service
nginx:
	@docker-compose -f $(COMPOSE_FILE) up -d --build nginx

mariadb:
	@docker-compose -f $(COMPOSE_FILE) up -d --build mariadb

wordpress:
	@docker-compose -f $(COMPOSE_FILE) up -d --build wordpress

## Stop and remove all containers
down:
	@echo "$(YELLOW)Stopping and removing containers...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) down

## Stop containers without removing
stop:
	@echo "$(YELLOW)Stopping containers...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) stop

## Start stopped containers
start:
	@echo "$(GREEN)Starting containers...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) start

## Restart all containers
restart: stop start

## Clean Docker system (containers, images, networks)
clean: down
	@echo "$(RED)Cleaning Docker system...$(NC)"
	@docker system prune -af

## Full clean - remove everything including volumes and data
fclean: clean
	@echo "$(RED)Removing all data and volumes...$(NC)"
	@sudo rm -rf $(DATA_PATH)/wordpress/* $(DATA_PATH)/mariadb/*
	@docker volume rm $$(docker volume ls -q) 2>/dev/null || true
	@docker network rm $$(docker network ls -q --filter name=$(PROJECT_NAME)) 2>/dev/null || true

## Rebuild everything from scratch
re: fclean
	@echo "$(BLUE)Rebuilding everything...$(NC)"
	@mkdir -p $(DATA_PATH)/wordpress $(DATA_PATH)/mariadb
	@$(MAKE) all

## Show container logs
logs:
	@docker-compose -f $(COMPOSE_FILE) logs -f

## Show specific service logs
logs-%:
	@docker-compose -f $(COMPOSE_FILE) logs -f $*

## Show running containers
ps:
	@docker-compose -f $(COMPOSE_FILE) ps

## Show all containers (including stopped)
psa:
	@docker-compose -f $(COMPOSE_FILE) ps -a

## Execute shell in specific container
exec-%:
	@docker-compose -f $(COMPOSE_FILE) exec $* sh

## Show container status
status:
	@echo "$(BLUE)=== Container Status ===$(NC)"
	@docker-compose -f $(COMPOSE_FILE) ps
	@echo "\n$(BLUE)=== Networks ===$(NC)"
	@docker network ls | grep $(PROJECT_NAME) || true
	@echo "\n$(BLUE)=== Volumes ===$(NC)"
	@docker volume ls | grep $(PROJECT_NAME) || true

## Git operations
push:
	@echo -n "Enter commit message: " && read msg && \
	git add . && git commit -m "$$msg" && git push

## Help message
help:
	@echo "$(BLUE)Available targets:$(NC)"
	@echo "$(GREEN)  all$(NC)      - Build and start all containers (default)"
	@echo "$(GREEN)  build$(NC)    - Build all containers"
	@echo "$(GREEN)  up$(NC)       - Start all containers"
	@echo "$(GREEN)  down$(NC)     - Stop and remove containers"
	@echo "$(GREEN)  stop$(NC)     - Stop containers without removing"
	@echo "$(GREEN)  start$(NC)    - Start stopped containers"
	@echo "$(GREEN)  restart$(NC)  - Restart all containers"
	@echo "$(GREEN)  clean$(NC)    - Clean Docker system"
	@echo "$(GREEN)  fclean$(NC)   - Remove everything (data, volumes, images)"
	@echo "$(GREEN)  re$(NC)       - Complete rebuild"
	@echo "$(GREEN)  logs$(NC)     - Show all logs"
	@echo "$(GREEN)  logs-SERVICE$(NC) - Show specific service logs"
	@echo "$(GREEN)  ps$(NC)       - Show running containers"
	@echo "$(GREEN)  status$(NC)   - Show full project status"
	@echo "$(GREEN)  exec-SERVICE$(NC) - Open shell in container"
	@echo "$(GREEN)  nginx$(NC)    - Build and start nginx only"
	@echo "$(GREEN)  mariadb$(NC)  - Build and start mariadb only"
	@echo "$(GREEN)  wordpress$(NC)- Build and start wordpress only"
	@echo "$(GREEN)  push$(NC)     - Git add, commit, and push"
	@echo "$(GREEN)  help$(NC)     - Show this help message"

# Default target
.DEFAULT_GOAL := help