#!/bin/bash
# Instala o Winthor Anywhere (IzPack 5) de forma nao-interativa.
# Uso: install-wta.sh
# Fallback: make wta-install (console oficial).

set -euo pipefail

log()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
ok()   { log "OK: $*"; }
warn() { log "AVISO: $*"; }
fail() { log "ERRO: $*" >&2; exit 1; }

WTA_HOME="${WTA_HOME:-/opt/pcsist/produtos}"
WTA_INSTALLER_DIR="${WTA_INSTALLER_DIR:-/opt/wta-installer}"
WTA_MARKER="${WTA_HOME}/.wta-installed"
KARAF_BIN="${WTA_HOME}/winthor/bin/karaf"
JAVA_BIN="${WTA_INSTALLER_DIR}/winthor-jdk-linux/bin/java"
SETUP_JAR="${WTA_INSTALLER_DIR}/winthor-setup-full.jar"
AUTO_TPL="${WTA_AUTO_TPL:-/opt/wta/auto-install.xml.tpl}"
AUTO_XML="${WTA_AUTO_XML:-/tmp/wta-auto-install.xml}"
EXPECT_SCRIPT="${WTA_EXPECT_SCRIPT:-/opt/wta/install-wta.exp}"

: "${WTA_ORACLE_HOST:=oracle-db}"
: "${WTA_ORACLE_PORT:=1521}"
: "${ORACLE_PDB:=WINT}"
: "${SCHEMA_DESTINO:=WINTHOR}"
: "${SCHEMA_PASSWORD:=}"
: "${WTA_LOJA:=1}"
: "${WTA_EMPRESA:=1}"
: "${WTA_HTTP_PORT:=8180}"
: "${WTA_SSH_PORT:=8101}"
: "${WTA_RMI_PORT:=1099}"
: "${WTA_ARTEMIS_PORT:=61616}"
: "${ORACLE_WAIT_SECONDS:=30}"
: "${WTA_INSTALL_RETRY_SECONDS:=30}"

xml_escape() {
  local s="$1"
  s="${s//&/&amp;}"
  s="${s//</&lt;}"
  s="${s//>/&gt;}"
  s="${s//\"/&quot;}"
  s="${s//\'/&apos;}"
  printf '%s' "$s"
}

detect_server_host() {
  if [ -n "${WTA_SERVER_HOST:-}" ]; then
    printf '%s' "$WTA_SERVER_HOST"
    return
  fi
  local ip
  ip="$(hostname -i 2>/dev/null | awk '{print $1}')"
  if [ -n "$ip" ]; then
    printf '%s' "$ip"
    return
  fi
  hostname -f 2>/dev/null || hostname
}

wta_already_installed() {
  [ -x "$KARAF_BIN" ] || [ -f "$WTA_MARKER" ]
}

wait_for_oracle() {
  local host="$WTA_ORACLE_HOST"
  local port="$WTA_ORACLE_PORT"
  log "Aguardando Oracle em ${host}:${port} (schema precisa existir: rode make init)..."
  while true; do
    if (echo >/dev/tcp/"$host"/"$port") >/dev/null 2>&1; then
      ok "Oracle aceitou conexao TCP em ${host}:${port}"
      return 0
    fi
    log "Oracle ainda nao escuta em ${host}:${port}; nova tentativa em ${ORACLE_WAIT_SECONDS}s"
    sleep "$ORACLE_WAIT_SECONDS"
  done
}

render_auto_xml() {
  [ -f "$AUTO_TPL" ] || fail "Template nao encontrado: $AUTO_TPL"
  [ -n "$SCHEMA_PASSWORD" ] || fail "SCHEMA_PASSWORD vazia. Defina no .env e recrie o container."

  local host_esc pdb_esc user_esc pass_esc loja_esc emp_esc \
        sport_esc http_esc ssh_esc rmi_esc art_esc shost_esc

  WTA_SERVER_HOST="$(detect_server_host)"
  export WTA_SERVER_HOST

  host_esc="$(xml_escape "$WTA_ORACLE_HOST")"
  pdb_esc="$(xml_escape "$ORACLE_PDB")"
  user_esc="$(xml_escape "$SCHEMA_DESTINO")"
  pass_esc="$(xml_escape "$SCHEMA_PASSWORD")"
  loja_esc="$(xml_escape "$WTA_LOJA")"
  emp_esc="$(xml_escape "$WTA_EMPRESA")"
  sport_esc="$(xml_escape "$WTA_ORACLE_PORT")"
  http_esc="$(xml_escape "$WTA_HTTP_PORT")"
  ssh_esc="$(xml_escape "$WTA_SSH_PORT")"
  rmi_esc="$(xml_escape "$WTA_RMI_PORT")"
  art_esc="$(xml_escape "$WTA_ARTEMIS_PORT")"
  shost_esc="$(xml_escape "$WTA_SERVER_HOST")"

  local content
  content="$(cat "$AUTO_TPL")"
  content="${content//\$\{WTA_ORACLE_HOST\}/${host_esc}}"
  content="${content//\$\{WTA_ORACLE_PORT\}/${sport_esc}}"
  content="${content//\$\{ORACLE_PDB\}/${pdb_esc}}"
  content="${content//\$\{SCHEMA_DESTINO\}/${user_esc}}"
  content="${content//\$\{SCHEMA_PASSWORD\}/${pass_esc}}"
  content="${content//\$\{WTA_LOJA\}/${loja_esc}}"
  content="${content//\$\{WTA_EMPRESA\}/${emp_esc}}"
  content="${content//\$\{WTA_SERVER_HOST\}/${shost_esc}}"
  content="${content//\$\{WTA_HTTP_PORT\}/${http_esc}}"
  content="${content//\$\{WTA_SSH_PORT\}/${ssh_esc}}"
  content="${content//\$\{WTA_RMI_PORT\}/${rmi_esc}}"
  content="${content//\$\{WTA_ARTEMIS_PORT\}/${art_esc}}"
  printf '%s\n' "$content" > "$AUTO_XML"
  log "auto-install.xml gerado em $AUTO_XML (host WTA=${WTA_SERVER_HOST})"
}

run_izpack_auto() {
  [ -x "$JAVA_BIN" ] || fail "Java do instalador nao encontrado: $JAVA_BIN"
  [ -f "$SETUP_JAR" ] || fail "JAR do instalador nao encontrado: $SETUP_JAR"
  mkdir -p "$WTA_HOME"
  cd "$WTA_INSTALLER_DIR"
  log "Iniciando IzPack -auto (conexao ${WTA_ORACLE_HOST}:${WTA_ORACLE_PORT}/${ORACLE_PDB} usuario ${SCHEMA_DESTINO})"
  "$JAVA_BIN" -Djava.awt.headless=true -jar "$SETUP_JAR" -language prt -auto "$AUTO_XML"
}

run_izpack_expect() {
  [ -f "$EXPECT_SCRIPT" ] || return 1
  log "Tentando instalacao via expect (console)..."
  export WTA_ORACLE_HOST WTA_ORACLE_PORT ORACLE_PDB SCHEMA_DESTINO SCHEMA_PASSWORD \
    WTA_LOJA WTA_EMPRESA WTA_HTTP_PORT WTA_SSH_PORT WTA_RMI_PORT WTA_ARTEMIS_PORT \
    WTA_SERVER_HOST JAVA_BIN SETUP_JAR WTA_INSTALLER_DIR
  expect -f "$EXPECT_SCRIPT"
}

install_once() {
  render_auto_xml
  if run_izpack_auto; then
    return 0
  fi
  warn "IzPack -auto falhou; tentando expect"
  run_izpack_expect || return 1
}

if wta_already_installed; then
  ok "WTA ja instalado em ${WTA_HOME}"
  exit 0
fi

[ -f "$SETUP_JAR" ] || fail "Instalador nao extraido em $WTA_INSTALLER_DIR"

wait_for_oracle

while true; do
  if install_once && wta_already_installed; then
    date -u +'%Y-%m-%dT%H:%M:%SZ' > "$WTA_MARKER"
    ok "Instalacao do WTA concluida"
    exit 0
  fi
  if wta_already_installed; then
    date -u +'%Y-%m-%dT%H:%M:%SZ' > "$WTA_MARKER"
    ok "Instalacao do WTA concluida"
    exit 0
  fi
  warn "Instalacao incompleta (schema pode nao existir ainda). Nova tentativa em ${WTA_INSTALL_RETRY_SECONDS}s. Rode make init no host se ainda nao rodou."
  sleep "$WTA_INSTALL_RETRY_SECONDS"
done
