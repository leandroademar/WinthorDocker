#!/bin/bash
# Importa o dump no PDB, remapeando SCHEMA_ORIGEM -> SCHEMA_DESTINO.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

require_vars ORACLE_USER ORACLE_PASSWORD ORACLE_HOST ORACLE_PORT ORACLE_PDB \
  SCHEMA_ORIGEM SCHEMA_DESTINO DUMP_DIR DUMP_FILE_NAME LOG_FILE_NAME

FULL_DUMP_FILE="${DUMP_DIR}/${DUMP_FILE_NAME}"

print_config

if [ ! -f "$FULL_DUMP_FILE" ]; then
  warn "Arquivo dump nao encontrado em ${FULL_DUMP_FILE}"
  warn "Monte o volume ./dump ou ajuste DUMP_FILE_NAME no .env. Pulando importacao."
  exit 0
fi

log "Arquivo de dump encontrado: ${FULL_DUMP_FILE}"
log "Iniciando impdp..."

PARFILE="$(mktemp /tmp/impdp-XXXXXX.par)"
cat > "$PARFILE" <<EOF
userid=${ORACLE_USER}/${ORACLE_PASSWORD}@${ORACLE_HOST}:${ORACLE_PORT}/${ORACLE_PDB}
directory=DUMP_DIR
dumpfile=${DUMP_FILE_NAME}
logfile=${LOG_FILE_NAME}
schemas=${SCHEMA_ORIGEM}
remap_schema=${SCHEMA_ORIGEM}:${SCHEMA_DESTINO}
EOF

status=0
impdp parfile="$PARFILE" || status=$?
rm -f "$PARFILE"

if [ "$status" -eq 0 ]; then
  ok "Importacao concluida. Log: ${DUMP_DIR}/${LOG_FILE_NAME}"
else
  fail "impdp retornou status=${status}. Verifique ${DUMP_DIR}/${LOG_FILE_NAME}"
fi

