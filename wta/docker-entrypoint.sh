#!/bin/bash
# Primeiro start: instala o WTA se /opt/pcsist/produtos ainda estiver vazio.
# Depois sobe Artemis (background) e o Karaf em foreground.

set -euo pipefail

log()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
ok()   { log "OK: $*"; }
warn() { log "AVISO: $*"; }
fail() { log "ERRO: $*" >&2; exit 1; }

WTA_HOME="${WTA_HOME:-/opt/pcsist/produtos}"
KARAF_BIN="${WTA_HOME}/winthor/bin/karaf"
ARTEMIS_HOME="${WTA_HOME}/artemis/bin/wtabroker"
: "${WTA_HTTP_PORT:=8180}"

chmod_tree() {
  local dir="$1"
  if [ -d "$dir" ]; then
    find "$dir" -type f \( -name '*.sh' -o -name 'karaf' -o -name 'start' -o -name 'stop' -o -name 'status' -o -name 'artemis' -o -name 'java' \) -exec chmod +x {} + 2>/dev/null || true
  fi
}

start_artemis() {
  local run="${ARTEMIS_HOME}/bin/artemis"
  local start_sh="${ARTEMIS_HOME}/bin/artemis-service-start.sh"
  if [ -x "$run" ]; then
    log "Iniciando Artemis em background"
    "$run" run >/proc/1/fd/1 2>/proc/1/fd/2 &
    return 0
  fi
  if [ -x "$start_sh" ]; then
    log "Iniciando Artemis via artemis-service-start.sh"
    "$start_sh" || warn "artemis-service-start.sh retornou $? (systemd pode nao existir no container)"
    return 0
  fi
  warn "Binario do Artemis nao encontrado; o Karaf pode subir sem mensageria"
}

start_karaf() {
  [ -x "$KARAF_BIN" ] || fail "Karaf nao encontrado em $KARAF_BIN"
  export KARAF_HOME="${WTA_HOME}/winthor"
  if [ -d "${WTA_HOME}/winthor-jdk" ]; then
    export JAVA_HOME="${WTA_HOME}/winthor-jdk"
  elif [ -d /opt/wta-installer/winthor-jdk-linux ]; then
    export JAVA_HOME="${WTA_INSTALLER_DIR:-/opt/wta-installer}/winthor-jdk-linux"
  fi
  log "Iniciando Karaf em foreground (HTTP ${WTA_HTTP_PORT})"
  cd "$KARAF_HOME"
  exec "$KARAF_BIN" server
}

if [ "${1:-}" = "install-only" ]; then
  exec /usr/local/bin/install-wta.sh
fi

if [ "${1:-}" = "console" ] || [ "${1:-}" = "wta-install" ]; then
  log "Instalador interativo (procedimento TOTVS: opcao 1 para continuar)"
  cd /opt/wta-installer
  exec bash ./install.sh
fi

if [ $# -gt 0 ] && [ "$1" != "wta" ] && [ "$1" != "start" ]; then
  exec "$@"
fi

if [ ! -x "$KARAF_BIN" ]; then
  log "WTA ainda nao instalado; iniciando install-wta.sh"
  /usr/local/bin/install-wta.sh
fi

chmod_tree "${WTA_HOME}/winthor"
chmod_tree "${WTA_HOME}/artemis"
chmod_tree "${WTA_HOME}/winthor-jdk"

start_artemis
start_karaf
