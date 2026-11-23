-- Connect to sage.hlsd.com:1521/sagepdb as SYS with SYSDBA authentication.
-- In DataGrip, run this entire block as one statement. Fresh install only.
-- Successful DDL persists if a later statement fails. Inspect before retrying.
declare
    prerequisite_count number;
    conflict_count number;
    invalid_count number;
    unsupported_actions varchar2(4000);
    ddl_actions constant varchar2(4000) := q'~
        create table, alter table, drop table, truncate table, rename,
        create index, alter index, drop index,
        create view, alter view, drop view,
        create materialized view, alter materialized view, drop materialized view,
        create sequence, alter sequence, drop sequence,
        create synonym, drop synonym,
        create procedure, alter procedure, drop procedure,
        create function, alter function, drop function,
        create package, alter package, drop package,
        create package body, alter package body, drop package body,
        create trigger, alter trigger, drop trigger,
        create type, alter type, drop type,
        create type body, alter type body, drop type body,
        create tablespace, alter tablespace, drop tablespace
    ~';
begin
    if nvl(upper(sys_context('USERENV', 'DB_UNIQUE_NAME')), '?') <> 'SAGE'
       or nvl(sys_context('USERENV', 'CON_NAME'), '?') <> 'SAGEPDB'
       or nvl(sys_context('USERENV', 'ISDBA'), 'FALSE') <> 'TRUE' then
        raise_application_error(-20001, 'Connect to SAGEPDB on SAGE as SYSDBA.');
    end if;

    select count(*) into prerequisite_count
    from v$parameter
    where name = 'max_string_size' and upper(value) = 'EXTENDED';

    if prerequisite_count <> 1 then
        raise_application_error(-20002, 'SAGEPDB must have MAX_STRING_SIZE=EXTENDED.');
    end if;

    select count(*) into prerequisite_count
    from dba_tablespaces
    where tablespace_name = 'APP_LOG' and status = 'ONLINE' and contents = 'PERMANENT';

    if prerequisite_count <> 1 then
        raise_application_error(-20003, 'APP_LOG must be an online permanent tablespace.');
    end if;

    select count(*) into conflict_count
    from (
        select username as name from dba_users where username = 'DB_ADMIN'
        union all
        select role from dba_roles where role in ('DB_ADMIN', 'DB_ADMIN_LOG_WRITER')
        union all
        select policy_name from audit_unified_policies
        where policy_name in ('SAGE_DDL_CHANGES', 'SAGE_LOGON_EVENTS')
    );

    if conflict_count > 0 then
        raise_application_error(-20004, 'An account, role, or policy already exists. Review the current state before continuing.');
    end if;

    select listagg(requested.action_name, ', ') within group (order by requested.action_name)
    into unsupported_actions
    from (
        select trim(regexp_substr(
            upper(regexp_replace(ddl_actions, '[[:space:]]+', ' ')),
            '[^,]+', 1, level
        )) as action_name
        from dual
        connect by level <= regexp_count(ddl_actions, ',') + 1
    ) requested
    where not exists (
        select 1 from auditable_system_actions supported
        where supported.name = requested.action_name
    );

    if unsupported_actions is not null then
        raise_application_error(-20006, 'Unsupported audit actions: ' || unsupported_actions);
    end if;

    execute immediate 'create user db_admin no authentication
        default tablespace app_log quota 3G on app_log';

    execute immediate 'grant select on sys.dba_data_files to db_admin';
    execute immediate 'grant select on sys.dba_free_space to db_admin';
    execute immediate 'grant execute on sys.dbms_utility to db_admin';

    execute immediate 'create sequence db_admin.seq_log_id start with 1000000';

    execute immediate q'~
        create table db_admin.db_system_log (
            log_id       number(32,0) default db_admin.seq_log_id.nextval not null,
            log_level    varchar2(1023 char),
            log_category varchar2(1023 char),
            log_message  varchar2(32767 byte),
            err_code     number(32,0),
            err_message  varchar2(32767 byte),
            backtrace    varchar2(32767 byte),
            callstack    varchar2(32767 byte),
            session_id   varchar2(1023 byte),
            create_date  date default sysdate not null,
            constraint pk_db_system_log primary key (log_id)
                using index tablespace app_log
        )
        tablespace app_log logging
        partition by range (create_date)
        interval (numtodsinterval(7, 'DAY'))
        (partition p0 values less than (date '2024-01-01'))
    ~';

    execute immediate q'~
        create view db_admin.view_tablespace_status as
        with files as (
            select tablespace_name, sum(bytes) as total_bytes,
                   sum(case when autoextensible = 'YES' then greatest(bytes, maxbytes)
                            else bytes end) as max_bytes
            from sys.dba_data_files
            group by tablespace_name
        ),
        free_extents as (
            select tablespace_name, sum(bytes) as free_bytes
            from sys.dba_free_space
            group by tablespace_name
        )
        select f.tablespace_name as "TABLESPACE",
               round((f.total_bytes - nvl(e.free_bytes, 0)) / 1048576, 1) as used_mb,
               round(nvl(e.free_bytes, 0) / 1048576, 1) as free_mb,
               round(f.total_bytes / 1048576, 1) as total_mb,
               round(f.max_bytes / 1048576, 1) as max_mb,
               round(100 * nvl(e.free_bytes, 0) / nullif(f.total_bytes, 0), 1)
                   as curr_pct_free,
               round(100 * (f.max_bytes - f.total_bytes + nvl(e.free_bytes, 0))
                     / nullif(f.max_bytes, 0), 1) as max_pct_free
        from files f
        left join free_extents e on e.tablespace_name = f.tablespace_name
    ~';

    execute immediate q'~
        create package db_admin.pkg_log authid definer as
            procedure log_any (log_level varchar2, category varchar2, message varchar2);
            procedure log_error (category varchar2 := 'UNKNOWN', message varchar2 := null);
            procedure log_warning (category varchar2, message varchar2 := null);
            procedure log_info (category varchar2, message varchar2);
            procedure log_debug (category varchar2, message varchar2);

            procedure log_error_details (
                category varchar2,
                message varchar2,
                error_code number,
                error_message varchar2,
                backtrace varchar2 := null,
                callstack varchar2 := null
            );
        end pkg_log;
    ~';

    execute immediate q'~
        create package body db_admin.pkg_log as
            procedure write_entry (
                p_level varchar2,
                p_category varchar2,
                p_message varchar2,
                p_code number := null,
                p_error varchar2 := null,
                p_backtrace varchar2 := null,
                p_callstack varchar2 := null
            ) is
                pragma autonomous_transaction;
            begin
                insert into db_admin.db_system_log (
                    log_level, log_category, log_message, err_code, err_message,
                    backtrace, callstack, session_id
                ) values (
                    substr(nvl(p_level, 'ERROR'), 1, 1023),
                    substr(nvl(p_category, 'UNKNOWN'), 1, 1023),
                    p_message, p_code, p_error, p_backtrace, p_callstack,
                    sys_context('USERENV', 'SESSIONID')
                );
                commit;
            exception
                when others then
                    rollback;
                    raise;
            end write_entry;

            procedure log_any (log_level varchar2, category varchar2, message varchar2) is
                caller_code number := sqlcode;
            begin
                if caller_code = 0 then
                    write_entry(log_level, category, message);
                else
                    write_entry(log_level, category, message, caller_code, sqlerrm,
                                sys.dbms_utility.format_error_backtrace,
                                sys.dbms_utility.format_call_stack);
                end if;
            end log_any;

            procedure log_error (category varchar2 := 'UNKNOWN', message varchar2 := null) is
            begin
                log_any('ERROR', category, message);
            end log_error;

            procedure log_warning (category varchar2, message varchar2 := null) is
            begin
                log_any('WARNING', category, message);
            end log_warning;

            procedure log_info (category varchar2, message varchar2) is
            begin
                log_any('INFO', category, message);
            end log_info;

            procedure log_debug (category varchar2, message varchar2) is
            begin
                log_any('DEBUG', category, message);
            end log_debug;

            procedure log_error_details (
                category varchar2,
                message varchar2,
                error_code number,
                error_message varchar2,
                backtrace varchar2 := null,
                callstack varchar2 := null
            ) is
            begin
                write_entry('ERROR', category, message, error_code, error_message,
                            backtrace, callstack);
            end log_error_details;
        end pkg_log;
    ~';

    select count(*) into invalid_count
    from dba_objects
    where owner = 'DB_ADMIN' and status <> 'VALID';

    if invalid_count > 0 then
        raise_application_error(-20005, 'Inspect DB_ADMIN compilation errors in DBA_ERRORS.');
    end if;

    execute immediate 'create role db_admin_log_writer';
    execute immediate 'grant execute on db_admin.pkg_log to db_admin_log_writer';

    execute immediate 'create audit policy sage_ddl_changes actions '
        || ddl_actions || ' container = current';
    execute immediate 'create audit policy sage_logon_events actions logon container = current';
    execute immediate 'audit policy sage_ddl_changes';
    execute immediate 'audit policy sage_logon_events';
end;
