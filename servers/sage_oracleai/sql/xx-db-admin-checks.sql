-- Run selected statements in DataGrip on SAGEPDB as SYSDBA.
select sys_context('USERENV', 'CON_NAME') as container_name from dual;

select username, authentication_type, default_tablespace
from dba_users
where username = 'DB_ADMIN';

select privilege, admin_option
from dba_sys_privs
where grantee = 'DB_ADMIN';

select granted_role, admin_option
from dba_role_privs
where grantee = 'DB_ADMIN';

select object_name, object_type, status
from dba_objects
where owner = 'DB_ADMIN'
order by object_type, object_name;

select name, type, line, position, text
from dba_errors
where owner = 'DB_ADMIN'
order by name, type, sequence;

select policy_name, enabled_option, entity_name, success, failure
from audit_unified_enabled_policies
where policy_name in ('SAGE_DDL_CHANGES', 'SAGE_LOGON_EVENTS')
order by policy_name;

-- Optional one-row logger smoke test. Select the complete BEGIN ... END; block.
-- begin
--     db_admin.pkg_log.log_info('SETUP_TEST', 'DataGrip logger smoke test');
-- end;

select log_id, create_date, log_level, log_category, log_message, err_code
from db_admin.db_system_log
order by log_id desc
fetch first 30 rows only;

-- Reconnect to test LOGON. For a DDL test, create and drop a disposable
-- table as the owner of a test schema with an appropriate quota.
select event_timestamp_utc, dbusername, action_name, object_schema,
       object_name, return_code, unified_audit_policies, sql_text
from unified_audit_trail
where event_timestamp_utc >= sys_extract_utc(systimestamp) - interval '7' day
  and regexp_like(unified_audit_policies,
      '(^|,[[:space:]]*)(SAGE_DDL_CHANGES|SAGE_LOGON_EVENTS)([[:space:]]*,|$)')
order by event_timestamp_utc desc
fetch first 100 rows only;

select * from db_admin.view_tablespace_status order by "TABLESPACE";

-- Read-only preview of the previous application-log retention target.
select count(*) as app_log_rows_older_than_30_days
from db_admin.db_system_log
where create_date < sysdate - 30;

-- Grant to the actual application user after replacing the placeholder.
-- grant db_admin_log_writer to <app_user>;
-- For definer-rights stored code that calls PKG_LOG, grant EXECUTE directly.
-- grant execute on db_admin.pkg_log to <app_code_owner>;
