#!/bin/bash
# Biblioteca compartilhada pelos scripts de bootstrap (dentro do container).
# Substitui apenas ${VAR} conhecidas — nao usa envsubst livre para preservar
# identificadores Oracle como v_$session, obj$, user$.

set -euo pipefail

COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "${COMMON_DIR}/.." && pwd)"

log()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
ok()   { log "OK: $*"; }
warn() { log "AVISO: $*"; }
fail() { log "ERRO: $*" >&2; exit 1; }

# Defaults alinhados ao .env.example (o Compose injeta as vars no container).
: "${ORACLE_SID:=ORLCDV}"
: "${ORACLE_PDB:=WINT}"
: "${ORACLE_PWD:=}"
: "${ORACLE_PASSWORD:=${ORACLE_PWD}}"
: "${ORACLE_USER:=system}"
: "${ORACLE_HOST:=localhost}"
: "${ORACLE_PORT:=1521}"
: "${ORACLE_WAIT_SECONDS:=30}"
: "${SCHEMA_DESTINO:=WINTHOR}"
: "${SCHEMA_PASSWORD:=}"
: "${SCHEMA_ORIGEM:=COAGRO}"
: "${TS_DADOS:=TS_DADOS}"
: "${TS_INDICE:=TS_INDICE}"
: "${TS_INITIAL_SIZE:=3G}"
: "${TS_NEXT_SIZE:=100M}"
: "${DUMP_DIR:=/dump}"
: "${DUMP_FILE_NAME:=backup_datapump_WINT_20260824-180001_%U.dmp}"
: "${LOG_FILE_NAME:=backup_datapump_WINT_20260824-180001_import.log}"
: "${MAIN_LOG:=${SCRIPTS_DIR}/init-db.log}"

require_vars() {
  local missing=0
  local name
  for name in "$@"; do
    if [ -z "${!name:-}" ]; then
      log "Variavel obrigatoria vazia: $name" >&2
      missing=1
    fi
  done
  if [ "$missing" -ne 0 ]; then
    fail "Defina as variaveis no .env e recrie o container (docker compose up -d)."
  fi
}

# Substitui somente ${NOME} das variaveis listadas. Cifras Oracle (v_$session) ficam intactas.
render_sql_template() {
  local src="$1"
  local dest="$2"
  local content var_name

  [ -f "$src" ] || fail "Template nao encontrado: $src"

  content="$(cat "$src")"
  for var_name in \
    ORACLE_SID ORACLE_PDB \
    SCHEMA_DESTINO SCHEMA_PASSWORD SCHEMA_ORIGEM \
    TS_DADOS TS_INDICE TS_INITIAL_SIZE TS_NEXT_SIZE \
    DUMP_DIR
  do
    content="${content//\$\{${var_name}\}/${!var_name}}"
  done

  printf '%s\n' "$content" > "$dest"
}

print_config() {
  log "===== Configuracao ====="
  log "ORACLE_SID=$ORACLE_SID"
  log "ORACLE_PDB=$ORACLE_PDB"
  log "ORACLE_USER=$ORACLE_USER"
  log "ORACLE_HOST=$ORACLE_HOST"
  log "ORACLE_PORT=$ORACLE_PORT"
  log "SCHEMA_ORIGEM=$SCHEMA_ORIGEM"
  log "SCHEMA_DESTINO=$SCHEMA_DESTINO"
  log "TS_DADOS=$TS_DADOS"
  log "TS_INDICE=$TS_INDICE"
  log "DUMP_DIR=$DUMP_DIR"
  log "DUMP_FILE_NAME=$DUMP_FILE_NAME"
  log "========================"
}
