-- Usuario/schema do Winthor. Idempotente: so cria se nao existir.
-- O container ja deve estar no PDB (ALTER SESSION no 01-init-db.sh).

WHENEVER SQLERROR EXIT SQL.SQLCODE

DECLARE
  v_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_count
    FROM dba_users
   WHERE username = '${SCHEMA_DESTINO}';

  IF v_count = 0 THEN
    EXECUTE IMMEDIATE
      'CREATE USER ${SCHEMA_DESTINO} IDENTIFIED BY "${SCHEMA_PASSWORD}"
         DEFAULT TABLESPACE ${TS_DADOS}
         TEMPORARY TABLESPACE TEMP
         QUOTA UNLIMITED ON ${TS_DADOS}';
  END IF;
END;
/

COMMIT;
EXIT;
