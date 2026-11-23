-- Template, not a live registration. Change YOUR_APP_OWNER, YOUR_LOG_TABLE,
-- PURGE_YOUR_LOG_TABLE, and both 30-day values to match your retention policy.
-- The table must use single-column DATE interval partitioning on CREATE_DATE.
-- Run the grant as SYSDBA on SAGEPDB, then create the procedure as the table
-- owner or as an administrator creating it in that owner's schema.
-- grant execute on sys.dbms_assert to YOUR_APP_OWNER;

-- Preview the same cutoff in DataGrip as the owner or as SYSDBA before enabling.
with cutoff as (select sysdate - 30 as cutoff_date from dual)
select partition_name, upper_bound, cutoff_date,
       case when upper_bound is null then 'UNRECOGNIZED_BOUND'
            when upper_bound <= cutoff_date then 'DROP_ELIGIBLE'
            else 'KEEP' end as retention_action
from (
    select partition_name, partition_position,
           json_value(high_value_json, '$.high_value'
                      returning date preserve time null on error) as upper_bound
    from all_tab_partitions
    where table_owner = 'YOUR_APP_OWNER' and table_name = 'YOUR_LOG_TABLE'
      and "INTERVAL" = 'YES'
)
cross join cutoff
order by partition_position;

-- Select the CREATE PROCEDURE statement through its END; and run it once.
create procedure YOUR_APP_OWNER.PURGE_YOUR_LOG_TABLE authid definer as
    retention_days constant pls_integer := 30;
    cutoff_date date := sysdate - retention_days;
    compatible_table number;
    bad_bounds number;
begin
    if nvl(upper(sys_context('USERENV', 'DB_UNIQUE_NAME')), '?') <> 'SAGE'
       or nvl(sys_context('USERENV', 'CON_NAME'), '?') <> 'SAGEPDB' then
        raise_application_error(-20001, 'Expected SAGEPDB on SAGE.');
    end if;

    if retention_days < 1 then
        raise_application_error(-20004, 'Retention must be at least one day.');
    end if;

    select count(*) into compatible_table
    from all_part_tables t
    join all_part_key_columns k on k.owner = t.owner and k.name = t.table_name
    join all_tab_columns c
      on c.owner = t.owner and c.table_name = t.table_name and c.column_name = k.column_name
    where t.owner = 'YOUR_APP_OWNER' and t.table_name = 'YOUR_LOG_TABLE'
      and t.partitioning_type = 'RANGE'
      and t."INTERVAL" is not null
      and t.partitioning_key_count = 1
      and k.object_type = 'TABLE' and k.column_name = 'CREATE_DATE'
      and c.data_type = 'DATE';

    if compatible_table <> 1 then
        raise_application_error(-20002, 'Expected interval partitions on the single DATE column CREATE_DATE.');
    end if;

    select count(*) into bad_bounds
    from all_tab_partitions
    where table_owner = 'YOUR_APP_OWNER' and table_name = 'YOUR_LOG_TABLE' and "INTERVAL" = 'YES'
      and json_value(high_value_json, '$.high_value'
                     returning date preserve time null on error) is null;

    if bad_bounds > 0 then
        raise_application_error(-20003, 'Unrecognized partition boundary.');
    end if;

    for part in (
        select partition_name
        from all_tab_partitions
        where table_owner = 'YOUR_APP_OWNER' and table_name = 'YOUR_LOG_TABLE' and "INTERVAL" = 'YES'
          and json_value(high_value_json, '$.high_value'
                         returning date preserve time null on error) <= cutoff_date
        order by partition_position
    ) loop
        execute immediate 'alter table YOUR_APP_OWNER.YOUR_LOG_TABLE drop partition '
            || sys.dbms_assert.enquote_name(part.partition_name, false)
            || ' update indexes';
    end loop;
end PURGE_YOUR_LOG_TABLE;

-- After reviewing the procedure and the preview, grant and register separately.
-- grant execute on YOUR_APP_OWNER.PURGE_YOUR_LOG_TABLE to db_admin;
-- insert into db_admin.db_partition_cleanup
--     (table_owner, table_name, purge_procedure, enabled)
-- values ('YOUR_APP_OWNER', 'YOUR_LOG_TABLE', 'PURGE_YOUR_LOG_TABLE', 'N');
-- commit;
--
-- To activate the reviewed registration:
-- update db_admin.db_partition_cleanup
-- set enabled = 'Y'
-- where table_owner = 'YOUR_APP_OWNER' and table_name = 'YOUR_LOG_TABLE';
-- commit;
