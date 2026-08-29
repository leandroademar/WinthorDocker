# Winthor Anywhere (WTA). Debian e homologado pela TOTVS.
# O instalador e IzPack 5 (Makeself + winthor-setup-full.jar + JDK 8 bundled).
# O zip Linux fica em assets/winthor-setup-1.9.0.zip (contexto de build: raiz do repo).

FROM debian:bookworm-slim

ARG WTA_SETUP_ZIP=assets/winthor-setup-1.9.0.zip

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    JAVA_TOOL_OPTIONS="-Djava.awt.headless=true" \
    WTA_HOME=/opt/pcsist/produtos \
    WTA_INSTALLER_DIR=/opt/wta-installer

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        unzip \
        procps \
        expect \
        iproute2 \
        libfontconfig1 \
        libfreetype6 \
    && rm -rf /var/lib/apt/lists/*

COPY ${WTA_SETUP_ZIP} /tmp/wta.zip

# Extrai o Makeself (jar + JDK) e descarta o .run.
RUN set -eux; \
    mkdir -p /tmp/wta-unpack "${WTA_INSTALLER_DIR}"; \
    unzip -q /tmp/wta.zip -d /tmp/wta-unpack; \
    RUNFILE="$(find /tmp/wta-unpack -type f -name '*.run' | head -n 1 || true)"; \
    [ -n "${RUNFILE}" ] || { echo "Nenhum winthor-setup-*.run em ${WTA_SETUP_ZIP}"; exit 1; }; \
    chmod +x "${RUNFILE}"; \
    "${RUNFILE}" --noexec --target "${WTA_INSTALLER_DIR}" --noprogress --nox11 --nochown; \
    chmod +x "${WTA_INSTALLER_DIR}/install.sh" \
              "${WTA_INSTALLER_DIR}/winthor-jdk-linux/bin/java"; \
    rm -rf /tmp/wta.zip /tmp/wta-unpack; \
    test -f "${WTA_INSTALLER_DIR}/winthor-setup-full.jar"

COPY wta/docker-entrypoint.sh wta/install-wta.sh /usr/local/bin/
COPY wta/auto-install.xml.tpl wta/install-wta.exp /opt/wta/

RUN chmod +x /usr/local/bin/docker-entrypoint.sh /usr/local/bin/install-wta.sh \
    && mkdir -p "${WTA_HOME}"

WORKDIR /opt/pcsist/produtos
EXPOSE 8180 8101 1099 61616

HEALTHCHECK --interval=30s --timeout=10s --start-period=15m --retries=20 \
    CMD curl -fsS "http://127.0.0.1:${WTA_HTTP_PORT:-8180}/" >/dev/null || exit 1

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
