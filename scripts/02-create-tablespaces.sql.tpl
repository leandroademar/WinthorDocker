-- Tablespaces do schema Winthor em BIGFILE (um datafile, ate ~32 TB com 8k).
-- Idempotente: cria se nao existir; se existir SMALLFILE e vazio, recria.
-- Caminho: /opt/oracle/oradata/${ORACLE_SID}/${ORACLE_PDB}/

WHENEVER SQLERROR EXIT SQL.SQLCODE

DECLARE
  PROCEDURE ensure_bigfile_ts(
    p_name     VARCHAR2,
    p_datafile VARCHAR2,
    p_size     VARCHAR2,
    p_next     VARCHAR2
  ) IS
    v_count    NUMBER;
    v_big      VARCHAR2(3);
    v_segs     NUMBER;
    v_sql      VARCHAR2(4000);
  BEGIN
    SELECT COUNT(*) INTO v_count
      FROM dba_tablespaces
     WHERE tablespace_name = p_name;

    IF v_count > 0 THEN
      SELECT bigfile INTO v_big
        FROM dba_tablespaces
       WHERE tablespace_name = p_name;

      IF v_big = 'YES' THEN
        RETURN;
      END IF;

      SELECT COUNT(*) INTO v_segs
        FROM dba_segments
       WHERE tablespace_name = p_name;

      IF v_segs > 0 THEN
        RAISE_APPLICATION_ERROR(
          -20001,
          'Tablespace '||p_name||' e SMALLFILE e tem segmentos; recrie vazio para converter a BIGFILE'
        );
      END IF;

      EXECUTE IMMEDIATE
        'DROP TABLESPACE '||p_name||' INCLUDING CONTENTS AND DATAFILES';
    END IF;

    v_sql :=
      'CREATE BIGFILE TABLESPACE '||p_name||
      ' DATAFILE '''||p_datafile||''' SIZE '||p_size||
      ' AUTOEXTEND ON NEXT '||p_next||' MAXSIZE UNLIMITED'||
      ' SEGMENT SPACE MANAGEMENT AUTO';
    EXECUTE IMMEDIATE v_sql;
  END;
BEGIN
  ensure_bigfile_ts(
    '${TS_DADOS}',
    '/opt/oracle/oradata/${ORACLE_SID}/${ORACLE_PDB}/${TS_DADOS}.dbf',
    '${TS_INITIAL_SIZE}',
    '${TS_NEXT_SIZE}'
  );
  ensure_bigfile_ts(
    '${TS_INDICE}',
    '/opt/oracle/oradata/${ORACLE_SID}/${ORACLE_PDB}/${TS_INDICE}.dbf',
    '${TS_INITIAL_SIZE}',
    '${TS_NEXT_SIZE}'
  );

  -- PDB nasce com USERS SMALLFILE (~32 GB). Tira o default antes do DROP.
  EXECUTE IMMEDIATE 'ALTER DATABASE DEFAULT TABLESPACE ${TS_DADOS}';

  FOR r IN (
    SELECT username
      FROM dba_users
     WHERE default_tablespace = 'USERS'
       AND username NOT IN ('SYS', 'SYSTEM')
  ) LOOP
    BEGIN
      EXECUTE IMMEDIATE
        'ALTER USER '||r.username||' DEFAULT TABLESPACE ${TS_DADOS}';
    EXCEPTION
      WHEN OTHERS THEN NULL;
    END;
  END LOOP;

  ensure_bigfile_ts(
    'USERS',
    '/opt/oracle/oradata/${ORACLE_SID}/${ORACLE_PDB}/USERS.dbf',
    '100M',
    '${TS_NEXT_SIZE}'
  );

  EXECUTE IMMEDIATE 'ALTER DATABASE DEFAULT TABLESPACE ${TS_DADOS}';
END;
/

ALTER SYSTEM SET CURSOR_SHARING=EXACT SCOPE=BOTH;
ALTER SYSTEM SET JOB_QUEUE_PROCESSES=10 SCOPE=BOTH;

EXIT;
