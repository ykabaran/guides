-- Fresh registry install. In DataGrip use SAGEPDB on SAGE as SYSDBA.
-- Select and execute the initial DECLARE ... END; block as one statement.
-- Existing DB_SYSTEM_LOG retention stays on its own job.
declare
    conflicts number;
    invalid_objects number;
    schedule_reference timestamp with time zone;
begin
    if nvl(upper(sys_context('USERENV', 'DB_UNIQUE_NAME')), '?') <> 'SAGE'
       or nvl(sys_context('USERENV', 'CON_NAME'), '?') <> 'SAGEPDB'
       or nvl(sys_context('USERENV', 'ISDBA'), 'FALSE') <> 'TRUE' then
        raise_application_error(-20001, 'Connect to SAGEPDB on SAGE as SYSDBA.');
    end if;

    select count(*) into conflicts
    from (
        select object_name from dba_objects
        where owner = 'DB_ADMIN'
          and object_name in ('DB_PARTITION_CLEANUP', 'RUN_REGISTERED_PURGES')
        union all
        select job_name from dba_scheduler_jobs
        where owner = 'DB_ADMIN'
          and job_name in ('JOB_REGISTERED_PURGES', 'JOB_PARTITION_CLEANUP')
    );

    if conflicts > 0 then
        raise_application_error(-20002, 'A cleanup registry, dispatcher, or legacy job already exists. Inspect before proceeding.');
    end if;

    execute immediate 'grant execute on sys.dbms_assert to db_admin';

    execute immediate q'~
        create table db_admin.db_partition_cleanup (
            table_owner     varchar2(128 byte) not null,
            table_name      varchar2(128 byte) not null,
            purge_procedure varchar2(128 byte) not null,
            enabled         char(1) default 'N' not null,
            constraint db_partition_cleanup_pk primary key (table_owner, table_name),
            constraint db_partition_cleanup_proc_uk unique (table_owner, purge_procedure),
            constraint db_partition_cleanup_enabled_ck check (enabled in ('Y', 'N')),
            constraint db_partition_cleanup_names_ck check (
                table_owner = upper(table_owner) and table_name = upper(table_name)
                and purge_procedure = upper(purge_procedure)
            )
        ) tablespace app_log logging
    ~';

    execute immediate q'~
        create procedure db_admin.run_registered_purges authid definer as
            valid_proc number;
            failure_count number := 0;
            first_error varchar2(1800);
        begin
            for entry in (
                select table_owner, table_name, purge_procedure
                from db_admin.db_partition_cleanup
                where enabled = 'Y'
                order by table_owner, table_name
            ) loop
                begin
                    if entry.table_owner in ('SYS', 'SYSTEM', 'AUDSYS')
                       or (entry.table_owner = 'DB_ADMIN' and entry.purge_procedure in
                           ('RUN_REGISTERED_PURGES', 'PURGE_SYSTEM_LOG')) then
                        raise_application_error(-20003, 'Procedure is reserved or managed by another job.');
                    end if;

                    select count(*) into valid_proc
                    from all_objects
                    where owner = entry.table_owner
                      and object_name = entry.purge_procedure
                      and object_type = 'PROCEDURE' and status = 'VALID'
                      and (
                          owner = 'DB_ADMIN'
                          or exists (
                              select 1 from all_tab_privs
                              where grantee = 'DB_ADMIN'
                                and table_schema = entry.table_owner
                                and table_name = entry.purge_procedure
                                and privilege = 'EXECUTE'
                          )
                      );

                    if valid_proc <> 1 then
                        raise_application_error(-20004, 'Expected a valid standalone procedure with direct EXECUTE.');
                    end if;

                    execute immediate 'begin '
                        || sys.dbms_assert.enquote_name(entry.table_owner, false)
                        || '.'
                        || sys.dbms_assert.enquote_name(entry.purge_procedure, false)
                        || '; end;';
                exception
                    when others then
                        failure_count := failure_count + 1;
                        if first_error is null then
                            first_error := substr(entry.table_owner || '.' || entry.table_name
                                || ': ' || sqlerrm, 1, 400);
                        end if;
                end;
            end loop;

            if failure_count > 0 then
                raise_application_error(-20005, failure_count
                    || ' registered purge(s) failed. First error: ' || first_error);
            end if;
        end run_registered_purges;
    ~';

    select count(*) into invalid_objects
    from dba_objects
    where owner = 'DB_ADMIN' and object_name = 'RUN_REGISTERED_PURGES'
      and object_type = 'PROCEDURE' and status = 'VALID';
    if invalid_objects <> 1 then
        raise_application_error(-20006, 'Inspect RUN_REGISTERED_PURGES in DBA_ERRORS before creating the job.');
    end if;

    select systimestamp at time zone 'Asia/Nicosia' into schedule_reference from dual;
    dbms_scheduler.create_job(
        job_name        => 'DB_ADMIN.JOB_REGISTERED_PURGES',
        job_type        => 'STORED_PROCEDURE',
        job_action      => 'DB_ADMIN.RUN_REGISTERED_PURGES',
        start_date      => schedule_reference,
        repeat_interval => 'FREQ=DAILY;BYHOUR=5;BYMINUTE=0;BYSECOND=0',
        enabled         => false,
        auto_drop       => false,
        comments        => 'Call explicitly registered, table-owner purge procedures.'
    );
end;

-- Inspect registrations and job status before activation.
select table_owner, table_name, purge_procedure, enabled
from db_admin.db_partition_cleanup
order by table_owner, table_name;

select owner, job_name, enabled, state, next_run_date
from dba_scheduler_jobs
where owner = 'DB_ADMIN' and job_name = 'JOB_REGISTERED_PURGES';

select log_date, status, error#, additional_info
from dba_scheduler_job_run_details
where owner = 'DB_ADMIN' and job_name = 'JOB_REGISTERED_PURGES'
order by log_date desc
fetch first 10 rows only;

-- After enabling a reviewed registry entry, enable the job separately.
-- begin
--     dbms_scheduler.enable('DB_ADMIN.JOB_REGISTERED_PURGES');
-- end;
