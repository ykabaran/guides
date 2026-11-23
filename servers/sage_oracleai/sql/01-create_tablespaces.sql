-- connect to sage as SYS with service name sagepdb

select sys_context('USERENV', 'CON_NAME') as container_name from dual;

alter profile DEFAULT limit password_life_time UNLIMITED;
select profile, limit from dba_profiles
where profile = 'DEFAULT' and resource_name = 'PASSWORD_LIFE_TIME';

select * from v$log;
select * from v$logfile;
select * from DBA_DATA_FILES;
select * from SYS.DBA_TABLESPACES;

/*
ALTER DATABASE DATAFILE <file_id> RESIZE 10G;
ALTER DATABASE DATAFILE <file_id> AUTOEXTEND ON NEXT 128M MAXSIZE 12G;
ALTER DATABASE DATAFILE <file_id> AUTOEXTEND OFF;

ALTER TABLESPACE app_main ADD DATAFILE SIZE 2G AUTOEXTEND OFF;
ALTER TABLESPACE app_main ADD DATAFILE SIZE 2G AUTOEXTEND ON NEXT 128M MAXSIZE 4G;

-- for bigfile tablespaces
ALTER TABLESPACE sysaux RESIZE 3G;
ALTER TABLESPACE sysaux AUTOEXTEND ON NEXT 128M MAXSIZE 4G;
*/

ALTER TABLESPACE system AUTOEXTEND ON NEXT 128M MAXSIZE 2G;
ALTER TABLESPACE sysaux AUTOEXTEND ON NEXT 128M MAXSIZE 4G;
ALTER TABLESPACE users  AUTOEXTEND ON NEXT 16M  MAXSIZE 100M;
ALTER TABLESPACE undotbs1 AUTOEXTEND ON NEXT 128M MAXSIZE 8G;

declare
    datafile_dest v$parameter.value%type;
    existing_tablespaces number;
begin
    if nvl(upper(sys_context('USERENV', 'DB_UNIQUE_NAME')), '?') <> 'SAGE'
       or nvl(sys_context('USERENV', 'CON_NAME'), '?') <> 'SAGEPDB' then
        raise_application_error(-20001, 'Connect to the SAGEPDB service on database SAGE.');
    end if;

    select trim(value) into datafile_dest
    from v$parameter where name = 'db_create_file_dest';

    if datafile_dest is null or
       (datafile_dest <> '/uoradata' and datafile_dest not like '/uoradata/%') then
        raise_application_error(-20002, 'Expected DB_CREATE_FILE_DEST under /uoradata.');
    end if;

    select count(*) into existing_tablespaces
    from dba_tablespaces
    where tablespace_name in ('APP_LOG', 'APP_CORE', 'APP_MAIN', 'APP_MAIN_INDEX');

    if existing_tablespaces > 0 then
        raise_application_error(-20003, 'At least one application tablespace already exists. Review before proceeding.');
    end if;

    execute immediate 'create smallfile tablespace app_log
        datafile size 4G autoextend off logging';

    execute immediate 'create smallfile tablespace app_core
        datafile size 1G autoextend off logging';

    execute immediate 'create smallfile tablespace app_main
        datafile size 8G autoextend off, size 8G autoextend off logging';

    execute immediate 'create smallfile tablespace app_main_index
        datafile size 8G autoextend off, size 8G autoextend off logging';
end;


SELECT SYS_CONTEXT('USERENV', 'CON_NAME') AS container_name,
       f.tablespace_name, t.bigfile, f.file_id,
       ROUND(f.bytes / 1048576, 1) AS size_mib,
       f.autoextensible,
       ROUND(f.maxbytes / 1048576, 1) AS autoextend_max_mib,
       f.file_name
FROM dba_data_files f
JOIN dba_tablespaces t ON t.tablespace_name = f.tablespace_name
ORDER BY f.tablespace_name, f.file_id;

with files as (
    select tablespace_name, count(*) as file_count, sum(bytes) as allocated_bytes,
           sum(case when autoextensible = 'YES' then greatest(bytes, maxbytes) else bytes end) as max_bytes
    from dba_data_files
    group by tablespace_name
),
free_extents as (
    select tablespace_name, sum(bytes) as free_bytes
    from dba_free_space
    group by tablespace_name
),
space_by_tablespace as (
    select f.tablespace_name, t.contents, t.status, f.file_count,
           f.allocated_bytes, f.max_bytes, nvl(e.free_bytes, 0) as free_bytes
    from files f
    join dba_tablespaces t on t.tablespace_name = f.tablespace_name
    left join free_extents e on e.tablespace_name = f.tablespace_name
)
select tablespace_name, contents, status, file_count,
       round((allocated_bytes - free_bytes) / 1048576, 1) as used_mib,
       round(free_bytes / 1048576, 1) as free_mib,
       round(allocated_bytes / 1048576, 1) as allocated_mib,
       round(max_bytes / 1048576, 1) as configured_max_mib,
       round(100 * free_bytes / nullif(allocated_bytes, 0), 1) as current_free_pct,
       round(100 * (max_bytes - allocated_bytes + free_bytes)
             / nullif(max_bytes, 0), 1) as max_free_pct
from space_by_tablespace
order by tablespace_name;