# Configuracao

Toda a parametrizacao do laboratorio fica no arquivo `.env` na raiz do repositorio.

```bash
cp .env.example .env
```

Nao commite o `.env`. Ele entra no `.gitignore` porque contem senhas.

O Docker Compose le o `.env` de duas formas:

- interpolacao do proprio Compose (`${ORACLE_SID}`, porta, imagem)
- `env_file: .env`, que injeta as mesmas variaveis no Oracle (`/scripts`) e no WTA

Depois de alterar variaveis oficiais do Oracle (`ORACLE_SID`, `ORACLE_PDB`, `ORACLE_PWD`, SGA/PGA, charset), recrie o container. Variaveis usadas so pelos scripts (`SCHEMA_*`, `DUMP_*`, `TS_*`) valem no proximo `make init` / `make import` se o container for recriado ou se voce as exportar no `docker compose exec`. Na pratica: `docker compose up -d --force-recreate` apos mudar o `.env`.

`ORACLE_SID`, `ORACLE_PDB` e `ORACLE_PWD` so tem efeito na **primeira** criacao do banco. Se `dados/oradata` ja tiver uma instancia, mudar SID/PDB/senha no `.env` nao altera o banco existente.

## Imagem e container

| Variavel | Default | Onde vale |
|---|---|---|
| `ORACLE_IMAGE` | `container-registry.oracle.com/database/enterprise:19.3.0.0` | Compose |
| `ORACLE_PLATFORM` | `linux/amd64` | Compose (`platform:`). Use `linux/arm64` com a tag `19.19.0.0` |
| `ORACLE_CONTAINER_NAME` | `oracle-enterprise` | Compose |
| `ORACLE_PORT` | `1521` | Compose (host:container) |

A tag `19.19.0.0` no repositorio `database/enterprise` e **somente linux/arm64**. Em host x86_64 use `19.3.0.0` (amd64). As duas precisam de aceite no [Oracle Container Registry](https://container-registry.oracle.com/).

## Instancia Oracle

Usadas pela imagem oficial na criacao do banco.

| Variavel | Default | Onde vale |
|---|---|---|
| `ORACLE_SID` | `ORLCDV` | Compose e caminho dos datafiles |
| `ORACLE_PDB` | `WINT` | Compose, sqlplus, impdp |
| `ORACLE_PWD` | (ver `.env.example`) | senha SYS/SYSTEM; scripts usam como `ORACLE_PASSWORD` |
| `ORACLE_EDITION` | `enterprise` | Compose |
| `ORACLE_CHARACTERSET` | `WE8MSWIN1252` | Compose |

## Recursos

| Variavel | Default | Onde vale |
|---|---|---|
| `INIT_SGA_SIZE` | `8192` | Compose (MB) |
| `INIT_PGA_SIZE` | `2048` | Compose (MB) |
| `INIT_CPU_COUNT` | `4` | Compose |
| `INIT_PROCESSES` | `900` | Compose |
| `ENABLE_ARCHIVELOG` | `true` | Compose |
| `ENABLE_FORCE_LOGGING` | `true` | Compose |
| `ENABLE_TCPS` | `true` | Compose |

## Schema Winthor

| Variavel | Default | Onde vale |
|---|---|---|
| `SCHEMA_DESTINO` | `WINTHOR` | SQL (usuario) e `remap_schema` |
| `SCHEMA_PASSWORD` | (ver `.env.example`) | `CREATE USER` e `make sql` |
| `SCHEMA_ORIGEM` | `COAGRO` | schema dentro do dump (`impdp`) |

## Tablespaces

Datafiles em `/opt/oracle/oradata/${ORACLE_SID}/${ORACLE_PDB}/`.

| Variavel | Default | Onde vale |
|---|---|---|
| `TS_DADOS` | `TS_DADOS` | SQL |
| `TS_INDICE` | `TS_INDICE` | SQL |
| `TS_INITIAL_SIZE` | `3G` | SQL |
| `TS_NEXT_SIZE` | `100M` | SQL |

## Dump

| Variavel | Default | Onde vale |
|---|---|---|
| `DUMP_DIR` | `/dump` | volume e `CREATE DIRECTORY` |
| `DUMP_BACKUP` | `dados/backup_datapump_WINT_20260824-180001.tar.gz` | host; `make dump-extract` |
| `DUMP_FILE_NAME` | `backup_datapump_WINT_20260824-180001_%U.dmp` | arquivo(s) em `./dump` (`%U` = 01, 02, ...) |
| `LOG_FILE_NAME` | `backup_datapump_WINT_20260824-180001_import.log` | log do `impdp` no mesmo volume |

## Operacao dos scripts

| Variavel | Default | Onde vale |
|---|---|---|
| `ORACLE_USER` | `system` | `impdp` |
| `ORACLE_HOST` | `localhost` | `impdp` (dentro do container) |
| `ORACLE_WAIT_SECONDS` | `30` | intervalo do wait em `01-init-db.sh` |

`ORACLE_PASSWORD` nao precisa ir no `.env`: os scripts copiam o valor de `ORACLE_PWD`.

## Winthor Anywhere (WTA)

O servico `wta` instala em `/opt/pcsist/produtos` (volume `dados/wta`). Host do banco **dentro** da rede Compose: `oracle-db` (`WTA_ORACLE_HOST`), nao `localhost`.

O instalador Linux e o arquivo `assets/winthor-setup-1.9.0.zip` (nao versionado). A imagem faz `COPY` desse zip no build.

| Variavel | Default | Onde vale |
|---|---|---|
| `WTA_SETUP_ZIP` | `assets/winthor-setup-1.9.0.zip` | build da imagem |
| `WTA_CONTAINER_NAME` | `wta` | Compose |
| `WTA_ORACLE_HOST` | `oracle-db` | instalador (JDBC) |
| `WTA_ORACLE_PORT` | `1521` | porta Oracle **na rede Docker** |
| `WTA_HTTP_PORT` | `8180` | HTTP Karaf e mapeamento host |
| `WTA_SSH_PORT` | `8101` | shell Karaf |
| `WTA_RMI_PORT` | `1099` | RMI |
| `WTA_ARTEMIS_PORT` | `61616` | mensageiro Artemis |
| `WTA_LOJA` | `1` | tela de login Winthor |
| `WTA_EMPRESA` | `1` | tela de login Winthor |
| `WTA_SERVER_HOST` | (IP do container) | IP/hostname gravado no WTA |
