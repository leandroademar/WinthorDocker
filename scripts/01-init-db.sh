#!/bin/bash
# Aguarda o Oracle ficar pronto e aplica tablespaces, usuario, grants e import.
# Executar dentro do container: /scripts/01-init-db.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

require_vars ORACLE_PDB ORACLE_SID SCHEMA_DESTINO SCHEMA_PASSWORD TS_DADOS TS_INDICE

aguardar_oracle() {
  log "Aguardando inicializacao do Oracle..." | tee -a "$MAIN_LOG"
  until sqlplus -s / as sysdba <<END
whenever sqlerror exit sql.sqlcode;
select 1 from dual;
exit;
END
  do
    log "Banco ainda nao esta pronto. Nova tentativa em ${ORACLE_WAIT_SECONDS}s..." | tee -a "$MAIN_LOG"
    sleep "$ORACLE_WAIT_SECONDS"
  done
  ok "Banco de dados esta pronto." | tee -a "$MAIN_LOG"
}

rodar_sql_template() {
  local template="$1"
  local log_file="$2"
  local rendered

  rendered="$(mktemp /tmp/wint-XXXXXX.sql)"
  render_sql_template "$template" "$rendered"

  log "Executando no PDB [${ORACLE_PDB}]: $(basename "$template")" | tee -a "$MAIN_LOG"

  local status=0
  sqlplus -s / as sysdba <<EOF > "$log_file" 2>&1 || status=$?
WHENEVER SQLERROR EXIT SQL.SQLCODE
ALTER SESSION SET CONTAINER=${ORACLE_PDB};
@${rendered}
EXIT
EOF

  rm -f "$rendered"

  if [ "$status" -eq 0 ]; then
    ok "Script $(basename "$template") executado (PDB=${ORACLE_PDB})." | tee -a "$MAIN_LOG"
  else
    fail "Falha ao executar $(basename "$template") (status=${status}). Detalhes: ${log_file}"
  fi
}

rodar_import_dump() {
  local import_script="$1"
  local log_file="$2"

  log "Importando dump via $(basename "$import_script")" | tee -a "$MAIN_LOG"

  local status=0
  bash "$import_script" > "$log_file" 2>&1 || status=$?

  if [ "$status" -eq 0 ]; then
    ok "Importacao concluida." | tee -a "$MAIN_LOG"
  else
    fail "Falha na importacao (status=${status}). Detalhes: ${log_file}"
  fi
}

echo "========================================" | tee -a "$MAIN_LOG"
log "Iniciando configuracao" | tee -a "$MAIN_LOG"
print_config | tee -a "$MAIN_LOG"
echo "========================================" | tee -a "$MAIN_LOG"

aguardar_oracle

rodar_sql_template "${SCRIPT_DIR}/02-create-tablespaces.sql.tpl" "${SCRIPT_DIR}/02-create-tablespaces.log"
rodar_sql_template "${SCRIPT_DIR}/03-create-users.sql.tpl"       "${SCRIPT_DIR}/03-create-users.log"
rodar_sql_template "${SCRIPT_DIR}/04-grant-permissions.sql.tpl"  "${SCRIPT_DIR}/04-grant-permissions.log"
rodar_import_dump  "${SCRIPT_DIR}/05-import-dump.sh"             "${SCRIPT_DIR}/05-import-dump.log"

echo "========================================" | tee -a "$MAIN_LOG"
ok "Configuracao concluida." | tee -a "$MAIN_LOG"
echo "========================================" | tee -a "$MAIN_LOG"

