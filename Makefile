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

DUMP_BACKUP ?= dados/backup_datapump_WINT_20260824-180001.tar.gz
DUMP_HOST_DIR ?= dump

# env_file so vale na criacao do container; exec precisa do .env atual.
COMPOSE_EXEC = $(COMPOSE) exec -T \
	-e DUMP_DIR="$(DUMP_DIR)" \
	-e DUMP_FILE_NAME="$(DUMP_FILE_NAME)" \
	-e LOG_FILE_NAME="$(LOG_FILE_NAME)" \
	-e SCHEMA_ORIGEM="$(SCHEMA_ORIGEM)" \
	-e SCHEMA_DESTINO="$(SCHEMA_DESTINO)" \
	-e SCHEMA_PASSWORD="$(SCHEMA_PASSWORD)" \
	-e ORACLE_PDB="$(ORACLE_PDB)" \
	-e ORACLE_PWD="$(ORACLE_PWD)" \
	-e ORACLE_PASSWORD="$(ORACLE_PWD)"

.PHONY: help up down logs logs-wta ps init import dump-extract sql wta-install wta-zip

help:
	@echo "Alvos:"
	@echo "  make up           - sobe Oracle + WTA (cria dump/, dados/oradata e dados/wta)"
	@echo "  make down         - para os containers"
	@echo "  make logs         - acompanha logs do Oracle"
	@echo "  make logs-wta    - acompanha logs do WTA"
	@echo "  make ps          - status do compose"
	@echo "  make dump-extract - descompacta DUMP_BACKUP em dump/"
	@echo "  make init        - tablespaces + usuario + grants + import (dentro do Oracle)"
	@echo "  make import      - descompacta o backup se preciso e roda impdp"
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

dump-extract:
	mkdir -p $(DUMP_HOST_DIR)
	@if ls $(DUMP_HOST_DIR)/*.dmp >/dev/null 2>&1; then \
		echo "OK: dump ja extraido em $(DUMP_HOST_DIR)/"; \
	elif [ -z "$(DUMP_BACKUP)" ]; then \
		echo "DUMP_BACKUP vazio; nada a extrair."; \
	elif [ ! -f "$(DUMP_BACKUP)" ]; then \
		echo "Backup nao encontrado: $(DUMP_BACKUP)"; exit 1; \
	else \
		echo "Extraindo $(DUMP_BACKUP) -> $(DUMP_HOST_DIR)/ (pode demorar)"; \
		tar -xzf "$(DUMP_BACKUP)" -C $(DUMP_HOST_DIR); \
		chown -R 54321:54321 $(DUMP_HOST_DIR) 2>/dev/null || chmod 777 $(DUMP_HOST_DIR); \
		ls -lh $(DUMP_HOST_DIR)/*.dmp; \
	fi

init: dump-extract
	$(COMPOSE_EXEC) $(SERVICE) /scripts/01-init-db.sh

import: dump-extract
	$(COMPOSE_EXEC) $(SERVICE) /scripts/05-import-dump.sh

sql:
	$(COMPOSE) exec -it $(SERVICE) sqlplus "$(SCHEMA_DESTINO)/$(SCHEMA_PASSWORD)@//localhost:1521/$(ORACLE_PDB)"

wta-install:
	$(COMPOSE) exec -it $(WTA_SERVICE) /usr/local/bin/docker-entrypoint.sh console

wta-zip:
	mkdir -p assets
	@if [ -f "$(WTA_SETUP_ZIP)" ]; then echo "OK: $(WTA_SETUP_ZIP)"; \
	else curl -fL --retry 3 -o "$(WTA_SETUP_ZIP)" "$(WTA_SETUP_ZIP_URL)"; fi
