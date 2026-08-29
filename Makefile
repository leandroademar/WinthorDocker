# Atalhos para o laboratorio Oracle/Winthor.
# Requer .env na raiz (cp .env.example .env).

COMPOSE := docker compose
SERVICE := oracle-db
WTA_SERVICE := wta

ifneq (,$(wildcard .env))
  include .env
  export
endif

WTA_SETUP_ZIP ?= assets/winthor-setup-1.9.0.zip
WTA_SETUP_ZIP_URL := https://storage.googleapis.com/artefatos-winthor/WTA-WinThorAnywhere/linux/winthor-setup-1.9.0.zip

.PHONY: help up down logs logs-wta ps init import sql wta-install wta-zip

help:
	@echo "Alvos:"
	@echo "  make up           - sobe Oracle + WTA (cria dump/, dados/oradata e dados/wta)"
	@echo "  make down         - para os containers"
	@echo "  make logs         - acompanha logs do Oracle"
	@echo "  make logs-wta    - acompanha logs do WTA"
	@echo "  make ps          - status do compose"
	@echo "  make init        - tablespaces + usuario + grants + import (dentro do Oracle)"
	@echo "  make import      - somente impdp"
	@echo "  make sql         - sqlplus no schema destino"
	@echo "  make wta-zip     - baixa o instalador Linux para assets/"
	@echo "  make wta-install - instalador WTA interativo (opcao 1 para continuar)"

up: wta-zip
	mkdir -p dump dados/oradata dados/wta
	@test -f .env || (echo "Crie o .env: cp .env.example .env" && exit 1)
	chown -R 54321:54321 dados/oradata dump 2>/dev/null || chmod 777 dados/oradata dump
	chmod 777 scripts
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

logs:
	$(COMPOSE) logs -f $(SERVICE)

logs-wta:
	$(COMPOSE) logs -f $(WTA_SERVICE)

ps:
	$(COMPOSE) ps

init:
	$(COMPOSE) exec $(SERVICE) /scripts/01-init-db.sh

import:
	$(COMPOSE) exec $(SERVICE) /scripts/05-import-dump.sh

sql:
	$(COMPOSE) exec -it $(SERVICE) sqlplus "$(SCHEMA_DESTINO)/$(SCHEMA_PASSWORD)@//localhost:1521/$(ORACLE_PDB)"

wta-install:
	$(COMPOSE) exec -it $(WTA_SERVICE) /usr/local/bin/docker-entrypoint.sh console

wta-zip:
	mkdir -p assets
	@if [ -f "$(WTA_SETUP_ZIP)" ]; then echo "OK: $(WTA_SETUP_ZIP)"; \
	else curl -fL --retry 3 -o "$(WTA_SETUP_ZIP)" "$(WTA_SETUP_ZIP_URL)"; fi
