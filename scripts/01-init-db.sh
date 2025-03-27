#!/bin/bash

########################################
# Script: init-db.sh
# Objetivo: Aguardar Oracle subir e rodar scripts no PDB
########################################

# Arquivo de log consolidado
MAIN_LOG="/scripts/init-db.log"

# Nome do PDB que você deseja usar
PDB_NAME="WINT"

# Função para aguardar a inicialização do Oracle
aguardar_oracle() {
  echo "⏳ Aguardando inicialização do Oracle..." | tee -a "$MAIN_LOG"
  until sqlplus -s / as sysdba <<END
whenever sqlerror exit sql.sqlcode;
select 1 from dual;
exit;
END
  do
    echo "⏳ Banco de dados ainda não está pronto. Tentando novamente em 10 minutos..." | tee -a "$MAIN_LOG"
    sleep 600
  done
  echo "✅ Banco de dados está pronto!" | tee -a "$MAIN_LOG"
}

# Função para rodar um script SQL dentro do PDB e logar saída
rodar_sql_script() {
  local sql_script="$1"
  local log_file="$2"

  echo "⚙️ Executando script no PDB [$PDB_NAME]: $sql_script" | tee -a "$MAIN_LOG"

  # Conecta como SYSDBA, muda para o PDB e roda o script
  sqlplus -s / as sysdba <<EOF > "$log_file" 2>&1
WHENEVER SQLERROR EXIT SQL.SQLCODE
ALTER SESSION SET CONTAINER=$PDB_NAME;
@${sql_script}
EXIT
EOF

  local status=$?
  if [ $status -eq 0 ]; then
    echo "   ✔ Script $sql_script executado com sucesso (PDB=$PDB_NAME)." | tee -a "$MAIN_LOG"
  else
    echo "   ❌ ERRO ao executar $sql_script (status=$status). Veja $log_file para detalhes." | tee -a "$MAIN_LOG"
  fi
}

# Função para rodar o script de importação (shell script) e logar saída
rodar_import_dump() {
  local import_script="$1"
  local log_file="$2"

  echo "📥 Importando dump via $import_script" | tee -a "$MAIN_LOG"
  bash "$import_script" > "$log_file" 2>&1
  local status=$?

  if [ $status -eq 0 ]; then
    echo "   ✔ Importação concluída." | tee -a "$MAIN_LOG"
  else
    echo "   ❌ ERRO na importação (status=$status). Veja $log_file para detalhes." | tee -a "$MAIN_LOG"
  fi
}

### Início do Script ###

echo "========================================" | tee -a "$MAIN_LOG"
echo "Iniciando configuração em $(date)" | tee -a "$MAIN_LOG"
echo "========================================" | tee -a "$MAIN_LOG"

# 1) Aguardar Oracle subir
aguardar_oracle

# 2) Executar scripts SQL de criação de tablespaces, usuários e permissões
rodar_sql_script "/scripts/02-create-tablespaces.sql" "/scripts/02-create-tablespaces.log"
rodar_sql_script "/scripts/03-create-users.sql"       "/scripts/03-create-users.log"
rodar_sql_script "/scripts/04-grant-permissions.sql"  "/scripts/04-grant-permissions.log"

# 3) Executar script de importação
rodar_import_dump "/scripts/05-import-dump.sh" "/scripts/05-import-dump.log"

echo "========================================" | tee -a "$MAIN_LOG"
echo "✅ Configuração concluída! Fim do script em $(date)" | tee -a "$MAIN_LOG"
echo "========================================" | tee -a "$MAIN_LOG"
