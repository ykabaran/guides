-- Optional. Connect to SAGEPDB as SYSDBA and run the whole block.
-- This installs the trigger DISABLED so you can check compilation first.
declare
    package_count number;
begin
    if nvl(upper(sys_context('USERENV', 'DB_UNIQUE_NAME')), '?') <> 'SAGE'
       or nvl(sys_context('USERENV', 'CON_NAME'), '?') <> 'SAGEPDB'
       or nvl(sys_context('USERENV', 'ISDBA'), 'FALSE') <> 'TRUE' then
        raise_application_error(-20001, 'Connect to SAGEPDB on SAGE as SYSDBA.');
    end if;

    select count(*) into package_count
    from dba_objects
    where owner = 'DB_ADMIN' and object_name = 'PKG_LOG'
      and object_type = 'PACKAGE BODY' and status = 'VALID';

    if package_count <> 1 then
        raise_application_error(-20002, 'Install and verify DB_ADMIN.PKG_LOG first.');
    end if;

    execute immediate 'grant administer database trigger to db_admin container = current';

    execute immediate q'~
        create trigger db_admin.trig_server_error
        after servererror on pluggable database
        disable
        declare
            error_code number;
            session_user_name varchar2(128);
        begin
            session_user_name := sys_context('USERENV', 'SESSION_USER');
            if session_user_name not in ('SYS', 'SYSTEM', 'DBSNMP', 'DB_ADMIN') then
                error_code := ora_server_error(1);
                if error_code is not null and error_code <> 0 then
                    db_admin.pkg_log.log_error_details(
                        category      => 'SERVER_ERROR',
                        message       => 'User: ' || session_user_name,
                        error_code    => -abs(error_code),
                        error_message => ora_server_error_msg(1)
                    );
                end if;
            end if;
        exception
            when others then
                -- The optional logger must never replace the client's original error.
                null;
        end;
    ~';
end;

-- Run these checks separately after installing the disabled trigger.
-- select status from dba_objects
-- where owner = 'DB_ADMIN' and object_name = 'TRIG_SERVER_ERROR' and object_type = 'TRIGGER';
-- select line, position, text from dba_errors
-- where owner = 'DB_ADMIN' and name = 'TRIG_SERVER_ERROR' order by sequence;
-- select status from dba_triggers
-- where owner = 'DB_ADMIN' and trigger_name = 'TRIG_SERVER_ERROR';
-- Enable separately after VALID / DISABLED and after reviewing expected log volume.
-- alter trigger db_admin.trig_server_error enable;
