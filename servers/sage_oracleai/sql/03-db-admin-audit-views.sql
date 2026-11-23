-- DataGrip Oracle connection: sage.hlsd.com:1521/sagepdb as SYSDBA.
-- Select and execute the DECLARE ... END; block as one statement.
declare
    schema_count number;
begin
    if nvl(upper(sys_context('USERENV', 'DB_UNIQUE_NAME')), '?') <> 'SAGE'
       or nvl(sys_context('USERENV', 'CON_NAME'), '?') <> 'SAGEPDB'
       or nvl(sys_context('USERENV', 'ISDBA'), 'FALSE') <> 'TRUE' then
        raise_application_error(-20001, 'Connect to SAGEPDB on SAGE as SYSDBA.');
    end if;

    select count(*) into schema_count
    from dba_users
    where username = 'DB_ADMIN' and common = 'NO';

    if schema_count <> 1 then
        raise_application_error(-20002, 'Expected the local DB_ADMIN schema.');
    end if;

    execute immediate 'grant select on audsys.unified_audit_trail to db_admin';

    execute immediate q'~
        create or replace view db_admin.view_logon_events as
        select event_timestamp_utc,
               dbusername,
               dbproxy_username,
               os_username,
               userhost,
               client_program_name,
               authentication_type,
               sessionid,
               return_code,
               case when return_code = 0 then 'SUCCESS' else 'FAILED' end as outcome,
               unified_audit_policies
        from audsys.unified_audit_trail
        where action_name = 'LOGON'
        with read only
    ~';

    execute immediate q'~
        create or replace view db_admin.view_ddl_changes as
        select event_timestamp_utc,
               dbusername,
               userhost,
               client_program_name,
               sessionid,
               action_name,
               object_schema,
               object_name,
               new_schema,
               new_name,
               return_code,
               case when return_code = 0 then 'SUCCESS' else 'FAILED' end as outcome,
               sql_text,
               unified_audit_policies
        from audsys.unified_audit_trail
        where regexp_like(unified_audit_policies,
                  '(^|,[[:space:]]*)SAGE_DDL_CHANGES([[:space:]]*,|$)')
        with read only
    ~';
end;

-- Verify each view separately as SYSDBA.
select event_timestamp_utc, dbusername, userhost, outcome, return_code
from db_admin.view_logon_events
order by event_timestamp_utc desc
fetch first 30 rows only;

select event_timestamp_utc, dbusername, action_name, object_schema,
       object_name, outcome, return_code, sql_text
from db_admin.view_ddl_changes
order by event_timestamp_utc desc
fetch first 30 rows only;
