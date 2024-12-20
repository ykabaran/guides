create user db_admin identified by ""
  default tablespace APP_LOG
  quota unlimited on APP_LOG
  quota unlimited on APP_LOG_INDEX;

grant connect, dba to db_admin;
grant
  select any table,
  select any dictionary,
  insert any table,
  update any table,
  delete any table,
  alter any table,
  drop any table
to db_admin with admin option;
GRANT ADMINISTER DATABASE TRIGGER TO db_admin;

alter session set current_schema=db_admin;

CREATE SEQUENCE seq_log_id START WITH 1000000;

create table DB_SYSTEM_LOG (
	LOG_ID       NUMBER(32,0) DEFAULT seq_log_id.nextval not null constraint PK_DB_SYSTEM_LOG primary key,
	LOG_LEVEL    VARCHAR2(1023),
	LOG_CATEGORY VARCHAR2(1023),
	LOG_MESSAGE  VARCHAR2(32767),
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
  (to_date('2024-01-01','YYYY-MM-DD'))
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
  (to_date('2024-01-01','YYYY-MM-DD'))
);
/

create table DB_PARTITION_CLEANUP (
  table_owner varchar2(1023),
  table_name varchar2(1023),
  table_column varchar2(1023),
  num_days number(16,0),
  delete_interval varchar2(1023),
  status varchar2(1023) default 'active'
);
/

insert into DB_PARTITION_CLEANUP (table_owner, table_name, table_column, num_days, delete_interval)
values ('DB_ADMIN', 'DB_SYSTEM_LOG', 'CREATE_DATE', 30, '1/24');
insert into DB_PARTITION_CLEANUP (table_owner, table_name, table_column, num_days, delete_interval)
values ('DB_ADMIN', 'DDL_HISTORY_LOG', 'CREATE_DATE', 1200, '1/24');

insert into DB_PARTITION_CLEANUP (table_owner, table_name, table_column, num_days, delete_interval)
values ('APP_LOG', 'APP_DATA_CHANGE_D1', 'PARTITION_DATE', 10, '5/(24*60)');
insert into DB_PARTITION_CLEANUP (table_owner, table_name, table_column, num_days, delete_interval)
values ('APP_LOG', 'APP_DATA_CHANGE_D7', 'PARTITION_DATE', 60, '1/24');
insert into DB_PARTITION_CLEANUP (table_owner, table_name, table_column, num_days, delete_interval)
values ('APP_LOG', 'APP_DATA_CHANGE_D30', 'PARTITION_DATE', 300, '1/24');
insert into DB_PARTITION_CLEANUP (table_owner, table_name, table_column, num_days, delete_interval)
values ('APP_LOG', 'APP_DATA_CHANGE_D300', 'PARTITION_DATE', 1200, '1/24');

insert into DB_PARTITION_CLEANUP (table_owner, table_name, table_column, num_days, delete_interval)
values ('APP_CORE', 'APP_DATA_CHANGE_D300', 'PARTITION_DATE', 1200, '1/24');

insert into DB_PARTITION_CLEANUP (table_owner, table_name, table_column, num_days, delete_interval)
values ('LS_LOG', 'INPLAY_FEED_FILE', 'PARTITION_DATE', 5, '5/(24*60)');
insert into DB_PARTITION_CLEANUP (table_owner, table_name, table_column, num_days, delete_interval)
values ('LS_LOG', 'PREMATCH_FEED_FILE', 'PARTITION_DATE', 5, '5/(24*60)');
insert into DB_PARTITION_CLEANUP (table_owner, table_name, table_column, num_days, delete_interval)
values ('LS_LOG', 'APP_DATA_CHANGE_D1', 'PARTITION_DATE', 10, '5/(24*60)');
insert into DB_PARTITION_CLEANUP (table_owner, table_name, table_column, num_days, delete_interval)
values ('LS_LOG', 'APP_DATA_CHANGE_D7', 'PARTITION_DATE', 60, '1/24');
insert into DB_PARTITION_CLEANUP (table_owner, table_name, table_column, num_days, delete_interval)
values ('LS_LOG', 'APP_DATA_CHANGE_D30', 'PARTITION_DATE', 300, '1/24');

insert into DB_PARTITION_CLEANUP (table_owner, table_name, table_column, num_days, delete_interval)
values ('GS_LOG', 'INPLAY_FEED_FILE', 'PARTITION_DATE', 5, '5/(24*60)');
insert into DB_PARTITION_CLEANUP (table_owner, table_name, table_column, num_days, delete_interval)
values ('GS_LOG', 'PREMATCH_FEED_FILE', 'PARTITION_DATE', 5, '5/(24*60)');
insert into DB_PARTITION_CLEANUP (table_owner, table_name, table_column, num_days, delete_interval)
values ('GS_LOG', 'APP_DATA_CHANGE_D1', 'PARTITION_DATE', 10, '5/(24*60)');
insert into DB_PARTITION_CLEANUP (table_owner, table_name, table_column, num_days, delete_interval)
values ('GS_LOG', 'APP_DATA_CHANGE_D7', 'PARTITION_DATE', 60, '1/24');
insert into DB_PARTITION_CLEANUP (table_owner, table_name, table_column, num_days, delete_interval)
values ('GS_LOG', 'APP_DATA_CHANGE_D30', 'PARTITION_DATE', 300, '1/24');

create or replace view VIEW_TABLESPACE_STATUS
AS select
   fs.tablespace_name                          tablespace,
   (df.totalspace - fs.freespace)              used_mb,
   fs.freespace                                free_mb,
   df.totalspace                               total_mb,
   df.MaxSpace                               max_mb,
   round(100 * (fs.freespace / df.totalspace)) curr_pct_free,
   round(100 * ((df.MaxSpace - (df.totalspace - fs.freespace)) / df.MaxSpace)) max_pct_free
from
   (select
      tablespace_name,
      round(sum(bytes) / 1048576) TotalSpace,
      round(sum(decode(nvl(maxbytes,0),0, bytes,maxbytes)) / 1048576) MaxSpace
   from
      sys.dba_data_files
   group by
      tablespace_name
   ) df,
   (select
      tablespace_name,
      round(sum(bytes) / 1048576) FreeSpace
   from
      sys.dba_free_space
   group by
      tablespace_name
   ) fs
where
   df.tablespace_name = fs.tablespace_name;


create PACKAGE pkg_log
AS
  PROCEDURE log_any (log_level VARCHAR2, category VARCHAR2, message VARCHAR2);

  PROCEDURE log_error (category VARCHAR2 := 'UNKNOWN', message VARCHAR2 := NULL);

  PROCEDURE log_warning (category VARCHAR2, message VARCHAR2 := NULL);

  PROCEDURE log_info (category VARCHAR2, message VARCHAR2);

  PROCEDURE log_debug (category VARCHAR2, message VARCHAR2);
END;
/

create PACKAGE BODY pkg_log
/* Formatted on 22-Nov-2018 16:35:55 (QP5 v5.276) */
AS
  PROCEDURE log_any (log_level VARCHAR2, category VARCHAR2, message VARCHAR2)
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
            decode(sql_code, 0, null, error_message),
            decode(sql_code, 0, null, DBMS_UTILITY.format_error_backtrace),
            decode(sql_code, 0, null, DBMS_UTILITY.format_call_stack),
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

  PROCEDURE log_error (category    VARCHAR2 := 'UNKNOWN', message VARCHAR2 := NULL)
  IS
  BEGIN
    pkg_log.log_any ('ERROR', category, message);
  END;

  ----------
  ----------

  PROCEDURE log_warning (category VARCHAR2, message VARCHAR2 := NULL)
  IS
  BEGIN
    pkg_log.log_any ('WARNING', category, message);
  END;

  ----------
  ----------

  PROCEDURE log_info (category VARCHAR2, message VARCHAR2)
  IS
  BEGIN
    pkg_log.log_any ('INFO', category, message);
  END;

  ----------
  ----------

  PROCEDURE log_debug (category VARCHAR2, message VARCHAR2)
  IS
  BEGIN
    pkg_log.log_any ('DEBUG', category, message);
  END;

END;
/

GRANT EXECUTE on PKG_LOG TO PUBLIC;

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

create or replace PACKAGE pkg_cleanup
AS
  PROCEDURE drop_old_partitions(
    xtable_owner varchar2, 
    xtable_name varchar2,
    xtable_column varchar2,
    xnum_days number,
    xdelete_interval varchar2);

  PROCEDURE do_partition_cleanup;
END;
/

create PACKAGE BODY pkg_cleanup
AS
  PROCEDURE drop_old_partitions(
    xtable_owner varchar2,
    xtable_name varchar2,
    xtable_column varchar2,
    xnum_days number,
    xdelete_interval varchar2)
  IS
    partition_date date;
  begin
    for rec in (select PARTITION_NAME, HIGH_VALUE
                from SYS.DBA_TAB_PARTITIONS where
                    table_owner = xtable_owner and table_name = xtable_name)
    loop
      execute immediate 'SELECT ' || rec.high_value || ' FROM DUAL' into partition_date;
      if partition_date < sysdate - xnum_days
      then
        db_admin.pkg_log.LOG_INFO('CLEANUP', 'deleting ' || xtable_owner || '.' || xtable_name || '.' || rec.PARTITION_NAME || ' - ' || to_char(partition_date, 'YYYY-MM-DD'));
        execute immediate 'ALTER TABLE ' || xtable_owner || '.' || xtable_name || ' MODIFY PARTITION ' || rec.PARTITION_NAME || ' NOLOGGING';
        execute immediate 'ALTER TABLE ' || xtable_owner || '.' || xtable_name || ' TRUNCATE PARTITION ' || rec.PARTITION_NAME || ' UPDATE INDEXES';
        /*
        execute immediate 'declare
          xstart_date date;
          xend_date date;
          xcurr_date date;
          delete_interval number := ' || xdelete_interval || ';
        begin
          select trunc(min(' || xtable_column || ')), trunc(max(' || xtable_column || ')+1)
          into xstart_date, xend_date
          from ' || xtable_owner || '.' || xtable_name || ' partition(' || rec.PARTITION_NAME || ');

          xcurr_date := xstart_date;
          while xcurr_date <= xend_date
          loop
            db_admin.pkg_log.LOG_INFO(''CLEANUP'', ''deleting curent date '' || to_char(xcurr_date, ''YYYY-MM-DD HH24:MI''));
            DELETE FROM ' || xtable_owner || '.' || xtable_name || ' PARTITION(' || rec.PARTITION_NAME || ') where ' || xtable_column || ' between xcurr_date - delete_interval and xcurr_date;
            commit;

            xcurr_date := xcurr_date + delete_interval;
          end loop;

          DELETE FROM ' || xtable_owner || '.' || xtable_name || ' PARTITION(' || rec.PARTITION_NAME || ');
          commit;
        end;';
        */
        execute immediate 'ALTER TABLE ' || xtable_owner || '.' || xtable_name || ' DROP PARTITION ' || rec.PARTITION_NAME;
        db_admin.pkg_log.LOG_INFO('CLEANUP', 'deleted ' || xtable_owner || '.' || xtable_name || '.' || rec.PARTITION_NAME || ' - ' || to_char(partition_date, 'YYYY-MM-DD'));
      end if;
    end loop;
  end;

  PROCEDURE do_partition_cleanup
  IS
  BEGIN
    for rec in (select table_owner, table_name, table_column, num_days, delete_interval
                  FROM DB_ADMIN.DB_PARTITION_CLEANUP WHERE status = 'active')
    loop
      begin
        drop_old_partitions(rec.table_owner, rec.table_name, rec.TABLE_COLUMN,rec.num_days, rec.delete_interval);
      exception when others then
        db_admin.pkg_log.log_error('CLEANUP', rec.table_owner || '.' || rec.table_name);
      end;
    end loop;
  END;
end;
/

BEGIN
  DBMS_SCHEDULER.CREATE_JOB (
    job_name   => 'DB_ADMIN.JOB_PARTITION_CLEANUP',
    job_type => 'STORED_PROCEDURE',
    job_action => 'PKG_CLEANUP.DO_PARTITION_CLEANUP',
    start_date    => SYSTIMESTAMP,
    repeat_interval  => 'FREQ=HOURLY; INTERVAL=1',
    auto_drop => FALSE,
    enabled => TRUE);
END;
/

