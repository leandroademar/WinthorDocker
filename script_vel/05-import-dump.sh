#!/bin/bash

########################################
# Script de Importação do Dump Oracle
# Objetivo:
#   - Verificar se o arquivo .dmp existe
#   - Executar impdp no PDB especificado
#   - Remapear o schema de origem para outro nome
########################################

# Variáveis de configuração
DUMP_DIR="/dump"                     # Caminho onde o arquivo de dump e log estão montados
DUMP_FILE_NAME="USER_FULL_VELETRICA.dmp"  # Nome do arquivo .dmp
LOG_FILE_NAME="USER_FULL_WINT_IMPORT_VEL.log"  # Nome do arquivo de log do import
ORACLE_PDB="WINTVEL"                    # Nome do PDB (Pluggable Database)
SCHEMA_ORIGEM="VELETRICA"               # Nome do schema de origem no dump
SCHEMA_DESTINO="WINTHOR"             # Nome do schema destino

# Credenciais e host de conexão ao Oracle
ORACLE_USER="system"
ORACLE_PASSWORD="S3nh4Admin01"
ORACLE_HOST="localhost"
ORACLE_PORT="1521"

########################################
# Exibe as configurações antes de iniciar
########################################
echo "===== Configurações de Importação ====="
echo "DUMP_DIR:       $DUMP_DIR"
echo "DUMP_FILE_NAME: $DUMP_FILE_NAME"
echo "LOG_FILE_NAME:  $LOG_FILE_NAME"
echo "ORACLE_PDB:     $ORACLE_PDB"
echo "SCHEMA_ORIGEM:  $SCHEMA_ORIGEM"
echo "SCHEMA_DESTINO: $SCHEMA_DESTINO"
echo "ORACLE_USER:    $ORACLE_USER"
echo "ORACLE_HOST:    $ORACLE_HOST"
echo "ORACLE_PORT:    $ORACLE_PORT"
echo "========================================"
echo

# Caminhos completos para dump e log
FULL_DUMP_FILE="$DUMP_DIR/$DUMP_FILE_NAME"

echo "📂 Iniciando importação do dump..."

# Verifica se o arquivo .dmp existe
if [ -f "$FULL_DUMP_FILE" ]; then
    echo "✅ Arquivo de dump encontrado: $FULL_DUMP_FILE"
    echo "   Iniciando impdp..."

    # Comando impdp
   impdp system/S3nh4Admin01@localhost:1521/WINT \
        directory=DUMP_DIR \
        dumpfile=USER_FULL_WINT.dmp \
        schemas=$SCHEMA_ORIGEM \
        remap_schema=$SCHEMA_ORIGEM:$SCHEMA_DESTINO

    # Verifica o status do impdp
    if [ $? -eq 0 ]; then
        echo "🎉 Importação concluída com sucesso!"
        echo "   Log de importação"
    else
        echo "❌ ERRO na importação. Verifique o log"
    fi
else
    echo "⚠️  Arquivo dump não encontrado em $FULL_DUMP_FILE"
    echo "    Verifique se o volume está montado corretamente ou se o arquivo existe."
    echo "    Pulando a importação..."
fi
