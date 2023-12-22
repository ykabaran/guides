alter session set current_schema=db_Admin;

-- select * from dba_part_tables where owner = 'DB_ADMIN';
-- select * from dba_part_indexes where owner = 'DB_ADMIN';
-- select * from DBA_TAB_PARTITIONS where table_owner = 'DB_ADMIN' and HIGH_VALUE > systimestamp;
-- select * from DBA_ind_PARTITIONS where index_owner = 'DB_ADMIN';

CREATE SEQUENCE seq_log_id START WITH 1000000;

create table DB_SYSTEM_LOG (
	LOG_ID       NUMBER(32,0) DEFAULT seq_log_id.nextval not null constraint PK_DB_SYSTEM_LOG primary key,
	LOG_LEVEL    VARCHAR2(1023),
	LOG_CATEGORY VARCHAR2(1023),
	LOG_MESSAGE  CLOB,
	ERR_CODE     NUMBER(32,0),
	ERR_MESSAGE  VARCHAR2(32767),
	BACKTRACE    VARCHAR2(32767),
	CALLSTACK    VARCHAR2(32767),
	SESSION_ID   VARCHAR2(1023),
	CREATE_DATE  DATE DEFAULT SYSDATE
)
partition by range(CREATE_DATE)
interval (numtodsinterval(7,'day'))
(partition p0 values less than
  (to_date('2022-01-01','YYYY-MM-DD'))
);
/

create table DDL_HISTORY_LOG (
	LOG_ID       NUMBER(32,0) DEFAULT seq_log_id.nextval not null constraint PK_DDL_HISTORY_LOG primary key,
	EVENT_TYPE      VARCHAR2(1023),
	OBJECT_OWNER    VARCHAR2(1023),
	OBJECT_NAME     VARCHAR2(1023),
	OBJECT_TYPE     VARCHAR2(1023),
	SESSION_ID		  VARCHAR2(1023),
	DDL_SQL         CLOB,
	OBJECT_SOURCE   CLOB,
	CREATE_DATE  DATE DEFAULT SYSDATE
)
partition by range(CREATE_DATE)
interval (numtodsinterval(7,'day'))
(partition p0 values less than
  (to_date('2022-01-01','YYYY-MM-DD'))
);
/

create PACKAGE pkg_log
AS
  PROCEDURE log_any (log_level VARCHAR2, category VARCHAR2, message CLOB);

  PROCEDURE log_error (category VARCHAR2 := 'UNKNOWN', message CLOB := NULL);

  PROCEDURE log_warning (category VARCHAR2, message CLOB := NULL);

  PROCEDURE log_info (category VARCHAR2, message CLOB);

  PROCEDURE log_debug (category VARCHAR2, message CLOB);
END;
/

create or replace PACKAGE BODY pkg_log
/* Formatted on 22-Nov-2018 16:35:55 (QP5 v5.276) */
AS
  PROCEDURE log_any (log_level VARCHAR2, category VARCHAR2, message CLOB)
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
		xlog_level varchar2(1023) := NVL(log_level, 'ERROR');
		xcategory varchar2(1023) := NVL(category, 'UNKNOWN');
  	sql_code number(32,0);
  	error_message varchar2(32767);
  BEGIN
    sql_code := SQLCODE;
    error_message := SQLERRM;

    INSERT INTO DB_SYSTEM_LOG (log_level,
                               log_category,
                               log_message,
                               err_code,
                               err_message,
                               backtrace,
                               callstack,
                               session_id)
    VALUES (xlog_level,
            xcategory,
            message,
            sql_code,
            error_message,
            DBMS_UTILITY.format_error_backtrace,
            DBMS_UTILITY.format_call_stack,
            SYS_CONTEXT('USERENV','SESSIONID'));

    COMMIT;
  EXCEPTION
    WHEN OTHERS
    THEN
      ROLLBACK;

      IF xlog_level != 'ERROR' AND xcategory != 'UNKNOWN'
      THEN
        pkg_log.log_error ();
      END IF;
  END;

  ----------
  ----------

  PROCEDURE log_error (category    VARCHAR2 := 'UNKNOWN', message     CLOB := NULL)
  IS
  BEGIN
    pkg_log.log_any ('ERROR', category, message);
  END;

  ----------
  ----------

  PROCEDURE log_warning (category VARCHAR2, message CLOB := NULL)
  IS
  BEGIN
    pkg_log.log_any ('WARNING', category, message);
  END;

  ----------
  ----------

  PROCEDURE log_info (category VARCHAR2, message CLOB)
  IS
  BEGIN
    pkg_log.log_any ('INFO', category, message);
  END;

  ----------
  ----------

  PROCEDURE log_debug (category VARCHAR2, message CLOB)
  IS
  BEGIN
    pkg_log.log_any ('DEBUG', category, message);
  END;

END;
/

CREATE OR REPLACE TRIGGER TRIG_DDL_CHANGE
	BEFORE CREATE OR ALTER OR DROP OR TRUNCATE OR RENAME
	ON DATABASE
DECLARE
	sql_text     ora_name_list_t;
	ddl_sql        CLOB;
  object_source  CLOB;
	object_type varchar2(1000);
BEGIN
	IF UPPER(sys.dictionary_obj_type) = 'USER'
	  OR UPPER(sys.dictionary_obj_owner) = 'SYS'
		OR UPPER(sys.dictionary_obj_name) = 'TRIG_DDL_CHANGE'
		OR UPPER(sys.dictionary_obj_name) like 'BIN$%'
	then
		return;
	end if;

	BEGIN
		FOR i IN 1 .. ora_sql_txt(sql_text)
			LOOP
				ddl_sql := ddl_sql || sql_text(i);
			END LOOP;
	EXCEPTION
		WHEN OTHERS THEN
	  	pkg_log.log_error();
	END;

	select upper(decode(sys.dictionary_obj_type, 'PACKAGE BODY', 'PACKAGE', sys.dictionary_obj_type))
	into object_type
	from dual;

	IF object_type IN ('PACKAGE', 'FUNCTION', 'PROCEDURE', 'VIEW', 'TABLE')
	then
	  begin
			object_source := DBMS_METADATA.get_ddl(object_type,
																			 sys.dictionary_obj_name,
																			 sys.dictionary_obj_owner);
		exception
	    when others then
	    	pkg_log.log_error();
		end;
	end if;

	INSERT INTO ddl_history_log (EVENT_TYPE,
																OBJECT_OWNER, OBJECT_NAME, OBJECT_TYPE,
																SESSION_ID,
																DDL_SQL, OBJECT_SOURCE)
	VALUES (ora_sysevent,
					sys.dictionary_obj_owner, sys.dictionary_obj_name, sys.dictionary_obj_type,
					SYS_CONTEXT('USERENV', 'SESSIONID'),
					ddl_sql, object_source);
EXCEPTION
	WHEN OTHERS
		THEN
			pkg_log.log_error();
END;
/

CREATE OR REPLACE TRIGGER TRIG_SERVER_ERROR
    AFTER SERVERERROR
    ON DATABASE
    WHEN (NVL (USER, 'NULL') NOT IN ('DBSNMP', 'SYS', 'SYSTEM'))
DECLARE
    sql_text   ora_name_list_t;
    sql_text_clob       clob;
BEGIN
  if SQLCODE = 0 then return; end if;

    BEGIN
			FOR i IN 1 .. ora_sql_txt (sql_text)
			LOOP
					sql_text_clob := sql_text_clob || sql_text (i);
			END LOOP;
    EXCEPTION
        WHEN OTHERS THEN
	  			pkg_log.log_error();
    END;

    pkg_log.log_error('SERVER_ERROR', sql_text_clob);
EXCEPTION
  WHEN OTHERS THEN
  	pkg_log.log_error();
END;
/

create or replace trigger trig_session_logon
	after logon
	on database
declare
  message clob;
begin
  message := message || 'USER: ' || USER || chr(10);
  message := message || 'SESSIONID: ' || SYS_CONTEXT('USERENV','SESSIONID') || chr(10);
  message := message || 'SID: ' || SYS_CONTEXT('USERENV','SID') || chr(10);
  message := message || 'OS_USER: ' || SYS_CONTEXT('USERENV','OS_USER') || chr(10);
  message := message || 'HOST: ' || SYS_CONTEXT('USERENV','HOST') || chr(10);
  message := message || 'IP_ADDRESS: ' || SYS_CONTEXT('USERENV','IP_ADDRESS') || chr(10);
  message := message || 'TERMINAL: ' || SYS_CONTEXT('USERENV','TERMINAL') || chr(10);
  message := message || 'ISDBA: ' || SYS_CONTEXT('USERENV','ISDBA') || chr(10);
  message := message || 'DB_NAME: ' || SYS_CONTEXT('USERENV','DB_NAME') || chr(10);
  message := message || 'EXTERNAL_NAME: ' || SYS_CONTEXT('USERENV','EXTERNAL_NAME') || chr(10);
  message := message || 'NETWORK_PROTOCOL: ' || SYS_CONTEXT('USERENV','NETWORK_PROTOCOL') || chr(10);

  pkg_log.log_info('SESSION_LOGON', message);
exception
	when others then
	  pkg_log.log_error();
end;
/


-- drop trigger trig_session_logon;
-- drop trigger TRIG_SERVER_ERROR;
-- drop trigger TRIG_DDL_CHANGE;
-- drop package body pkg_log;
-- drop package pkg_log;
-- drop table DDL_HISTORY_LOG;
-- drop table DB_SYSTEM_LOG;
-- drop sequence seq_log_id;
