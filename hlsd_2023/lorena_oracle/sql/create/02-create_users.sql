alter session set current_schema=SYS;

alter profile DEFAULT limit password_life_time UNLIMITED;

create user db_admin identified by ""
  default tablespace APP_LOG
  quota unlimited on APP_LOG;

create user app_log identified by ""
  default tablespace APP_LOG
  quota unlimited on APP_LOG;

create user app_core identified by ""
  default tablespace APP_CORE
  quota unlimited on APP_CORE;

/*
create user app_main identified by ""
  default tablespace APP_MAIN
  quota unlimited on APP_MAIN
  quota unlimited on APP_MAIN_INDEX
	quota unlimited on APP_LOG;
*/

grant connect, dba to db_admin;
grant select any dictionary to db_admin with admin option;
GRANT ADMINISTER DATABASE TRIGGER TO db_admin;

grant connect, resource to app_log;
grant connect, resource to app_core;
--grant connect, resource to app_main;

create role app_log_reader;
create role app_log_writer;
create role app_core_reader;
create role app_core_writer;

grant connect to app_log_reader;
grant connect to app_log_writer;
grant connect to app_core_reader;
grant connect to app_core_writer;
