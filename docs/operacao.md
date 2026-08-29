# Operacao

## Subir e parar

```bash
cp .env.example .env          # so na primeira vez
make up                       # cria dump/, dados/oradata e dados/wta
make logs                     # acompanhe a criacao do banco
make logs-wta                # instalacao do WTA (depois do Oracle healthy)
make ps                       # healthcheck (pmon / WTA)
make down                     # para os containers (dados permanecem)
```

A primeira subida da imagem Oracle 19c Enterprise costuma levar 15–30 minutos. O healthcheck tem `start_period` de 15 minutos. O WTA so inicia depois do Oracle `healthy`.

## Quando usar init e quando usar so import

| Situacao | Comando |
|---|---|
| Banco novo, ainda sem schema Winthor | `make init` |
| Schema e grants ja existem; so falta o dump | `make import` |
| Reexecutar init depois de um erro | `make init` de novo (tablespace e usuario sao idempotentes) |

`make init` espera o banco, aplica os templates SQL (tablespaces, usuario, grants) e chama o import. Se o arquivo `.dmp` nao estiver em `dump/`, o import e pulado e o restante do init termina com sucesso.

O Compose **nao** dispara o init no start. Isso e proposital: o dump pode nao estar montado e o `impdp` e longo.

O WTA espera o schema: se `make up` rodar antes do `make init`, o instalador tenta de novo ate o usuario `${SCHEMA_DESTINO}` existir. Acompanhe com `make logs-wta`.

Apos a instalacao, acesse `http://localhost:${WTA_HTTP_PORT}` e complete o wizard de configuracao inicial no browser (nao e automatizado).

Se a automacao IzPack falhar, use o console oficial:

```bash
make wta-install
```

Na tela de boas-vindas, pressione `1` e Enter (continuar).

## Onde ficam dump, dados e logs

| Caminho no host | Caminho no container | Conteudo |
|---|---|---|
| `dump/` | `/dump` | `.dmp` e log do `impdp` (`LOG_FILE_NAME`) |
| `dados/oradata` | `/opt/oracle/oradata` | datafiles persistentes |
| `dados/wta` | `/opt/pcsist/produtos` | `artemis`, `winthor-jdk`, `winthor` |
| `assets/winthor-setup-1.9.0.zip` | (build) | instalador Linux do WTA |
| `scripts/*.log` | `/scripts/*.log` | saida do init e dos SQL (gitignore) |

Coloque o dump em `dump/` com o nome de `DUMP_FILE_NAME` **antes** de `make init` ou `make import`.

## Conexao

```bash
make sql
docker compose exec oracle-db sqlplus / as sysdba
sqlplus WINTHOR/<SCHEMA_PASSWORD>@//localhost:1521/WINT
```

Service name = `ORACLE_PDB`. Porta no host = `ORACLE_PORT`.

WTA: `http://localhost:${WTA_HTTP_PORT}` (default 8180). Usuario e senha iguais aos do Winthor depois do wizard inicial.

## Troubleshooting

### PDB nao abre / listener sem servico

Aguarde o fim da criacao (`make logs` ate mensagens de DATABASE IS READY). Confira `ORACLE_PDB` no `.env` e se `dados/oradata` nao e de outra instancia (SID/PDB diferentes).

```bash
docker compose exec oracle-db sqlplus -s / as sysdba <<'SQL'
SHOW PDBS;
SQL
```

### Dump ausente

O import registra aviso e sai 0 se `/dump/${DUMP_FILE_NAME}` nao existir. Confira o nome no `.env` e o arquivo em `./dump`.

### Caminho do tablespace (ORA-01119 / diretorio inexistente)

Os datafiles usam `/opt/oracle/oradata/${ORACLE_SID}/${ORACLE_PDB}/`. O valor antigo `ORLCD` (sem o `V`) estava errado para `ORACLE_SID=ORLCDV`. Se o diretorio do PDB nao existir, o SQL falha; o log fica em `scripts/02-create-tablespaces.log`.

### Directory do impdp (ORA-39087 / invalid directory)

O objeto `DUMP_DIR` e criado em `04-grant-permissions.sql.tpl` apontando para `${DUMP_DIR}` (`/dump`). Rode `make init` (ou so o passo de grants) antes de `make import`. O volume `./dump:/dump` precisa estar montado.

### Senha SYSTEM recusada no impdp

`ORACLE_PWD` so vale na primeira criacao. Se o volume `dados/oradata` ja existia, a senha do banco e a antiga. Use a senha real ou recrie os datafiles (apaga a instancia).

### Container unhealthy por muito tempo

Na primeira subida e normal. Se passar de ~40 minutos, veja `make logs`. `pgrep pmon` e o teste do healthcheck: se o processo de instancia nao subiu, o banco nao inicializou.

### Mudou o `.env` e nada mudou

Recrie o container para injetar o `env_file` de novo:

```bash
docker compose up -d --force-recreate
```

Lembre: SID/PDB/senha da imagem nao mudam num datafile ja criado.

### WTA nao instala / fica reiniciando

Confira `make logs-wta`. Causas comuns:

- `make init` ainda nao rodou (schema `${SCHEMA_DESTINO}` inexistente)
- `WTA_ORACLE_HOST` nao e `oracle-db` (nao use `localhost` de dentro do container)
- `WTA_LOJA` / `WTA_EMPRESA` diferentes do cadastro no dump
- sem internet para `repo.pcinformatica.com.br` / `hub.pcinformatica.com.br`
- falta `assets/winthor-setup-1.9.0.zip` — rode `make wta-zip` e `docker compose build wta`

Instalacao persistente: apagar `dados/wta` forca reinstalar.

### WTA instalou mas a porta 8180 nao responde

O instalador pode ter tentado `systemctl` (inexistente no container). O entrypoint sobe o Karaf em foreground. Veja se `/opt/pcsist/produtos/winthor/bin/karaf` existe (`docker compose exec wta ls /opt/pcsist/produtos`). Recrie o container WTA sem apagar o volume: `docker compose up -d --force-recreate wta`.
