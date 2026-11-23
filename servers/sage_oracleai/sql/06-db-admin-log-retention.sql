-- DataGrip Oracle connection: sage.hlsd.com:1521/sagepdb, as SYSDBA.
-- Install DB_ADMIN using sage-db-admin-setup.sql first if needed.
-- Select and run only this initial DECLARE ... END; block to install.
-- The Scheduler job is created disabled. Initial installation does not purge.
declare
    compatible_table_count number;
    existing_job_count number;
    invalid_object_count number;
    schedule_reference timestamp with time zone;
begin
    if nvl(upper(sys_context('USERENV', 'DB_UNIQUE_NAME')), '?') <> 'SAGE'
       or nvl(sys_context('USERENV', 'CON_NAME'), '?') <> 'SAGEPDB'
       or nvl(sys_context('USERENV', 'ISDBA'), 'FALSE') <> 'TRUE' then
        raise_application_error(-20001, 'Connect to SAGEPDB on SAGE as SYSDBA.');
    end if;

    select count(*) into compatible_table_count
    from dba_part_tables t
    join dba_part_key_columns k on k.owner = t.owner and k.name = t.table_name
    join dba_tab_columns c
      on c.owner = t.owner and c.table_name = t.table_name and c.column_name = k.column_name
    where t.owner = 'DB_ADMIN'
      and t.table_name = 'DB_SYSTEM_LOG'
      and t.partitioning_type = 'RANGE'
      and t."INTERVAL" is not null
      and t.partitioning_key_count = 1
      and k.object_type = 'TABLE'
      and k.column_name = 'CREATE_DATE'
      and c.data_type = 'DATE';

    if compatible_table_count <> 1 then
        raise_application_error(-20002, 'Expected DB_ADMIN.DB_SYSTEM_LOG partitioned by interval on CREATE_DATE.');
    end if;

    select count(*) into existing_job_count
    from dba_scheduler_jobs
    where owner = 'DB_ADMIN'
      and job_name in ('JOB_SYSTEM_LOG_RETENTION', 'JOB_PARTITION_CLEANUP');

    if existing_job_count <> 0 then
        raise_application_error(-20003, 'An existing log cleanup job needs review before installation.');
    end if;

    execute immediate 'grant execute on sys.dbms_assert to db_admin';

    execute immediate q'~
        create or replace view db_admin.view_system_log_retention as
        select partition_name, partition_position, upper_bound, cutoff_date,
               case
                   when nvl(is_interval, 'NO') <> 'YES' then 'KEEP_RANGE'
                   when upper_bound is null then 'UNRECOGNIZED_BOUND'
                   when upper_bound <= cutoff_date then 'DROP_ELIGIBLE'
                   else 'KEEP'
               end as retention_action
        from (
            select partition_name, partition_position, "INTERVAL" as is_interval,
                   json_value(high_value_json, '$.high_value'
                              returning date preserve time null on error) as upper_bound,
                   sysdate - 30 as cutoff_date
            from all_tab_partitions
            where table_owner = 'DB_ADMIN' and table_name = 'DB_SYSTEM_LOG'
        )
    ~';

    execute immediate q'~
        create or replace procedure db_admin.purge_system_log authid definer as
            bad_bounds number;
        begin
            select count(*) into bad_bounds
            from db_admin.view_system_log_retention
            where retention_action = 'UNRECOGNIZED_BOUND';

            if bad_bounds > 0 then
                raise_application_error(-20004, 'Unknown system log partition boundary. No partitions deleted.');
            end if;

            for part in (
                select partition_name
                from db_admin.view_system_log_retention
                where retention_action = 'DROP_ELIGIBLE'
                order by partition_position
            ) loop
                execute immediate 'alter table db_admin.db_system_log drop partition '
                    || sys.dbms_assert.enquote_name(part.partition_name, false)
                    || ' update indexes';
            end loop;
        end purge_system_log;
    ~';

    select count(*) into invalid_object_count
    from dba_objects
    where owner = 'DB_ADMIN'
      and object_name in ('VIEW_SYSTEM_LOG_RETENTION', 'PURGE_SYSTEM_LOG')
      and status <> 'VALID';

    if invalid_object_count <> 0 then
        raise_application_error(-20005, 'Check DBA_ERRORS for invalid retention objects.');
    end if;

    select systimestamp at time zone 'Asia/Nicosia' into schedule_reference from dual;

    dbms_scheduler.create_job(
        job_name        => 'DB_ADMIN.JOB_SYSTEM_LOG_RETENTION',
        job_type        => 'STORED_PROCEDURE',
        job_action      => 'DB_ADMIN.PURGE_SYSTEM_LOG',
        start_date      => schedule_reference,
        repeat_interval => 'FREQ=DAILY;BYHOUR=4;BYMINUTE=30;BYSECOND=0',
        enabled         => false,
        auto_drop       => false,
        comments        => 'Drop complete DB_SYSTEM_LOG interval partitions outside the 30-day window.'
    );
end;

-- Preview before enabling. Only DROP_ELIGIBLE partitions can be purged.
select partition_name, upper_bound, cutoff_date, retention_action
from db_admin.view_system_log_retention
order by partition_position;

select tablespace_name, round(bytes / 1048576, 1) as allocated_mib,
       round(max_bytes / 1048576, 1) as quota_mib
from dba_ts_quotas
where username = 'DB_ADMIN' and tablespace_name = 'APP_LOG';

select owner, job_name, enabled, state, next_run_date
from dba_scheduler_jobs
where owner = 'DB_ADMIN' and job_name = 'JOB_SYSTEM_LOG_RETENTION';

-- After reviewing the preview, uncomment and run this block separately.
-- begin
--     dbms_scheduler.enable('DB_ADMIN.JOB_SYSTEM_LOG_RETENTION');
-- end;

-- After the first scheduled execution, check the job result.
select log_date, status, error#, additional_info
from dba_scheduler_job_run_details
where owner = 'DB_ADMIN' and job_name = 'JOB_SYSTEM_LOG_RETENTION'
order by log_date desc
fetch first 10 rows only;
