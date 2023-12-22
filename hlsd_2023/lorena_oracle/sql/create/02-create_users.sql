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

create user lsports_main identified by ""
  default tablespace APP_MAIN
  quota unlimited on APP_MAIN
  quota unlimited on APP_MAIN_INDEX
	quota unlimited on APP_LOG;

create user lsports_hlbs identified by ""
	default tablespace APP_MAIN
	quota unlimited on APP_MAIN
  quota unlimited on APP_MAIN_INDEX
	quota unlimited on APP_LOG;

grant connect, dba to db_admin;
GRANT ADMINISTER DATABASE TRIGGER TO db_admin;
grant connect, resource to app_log;
grant connect, resource to app_core;
grant connect, resource to lsports_main;
grant connect, resource to lsports_hlbs;

create role app_log_role;
create role app_log_analyzer_role;
create role app_user_role;
create role app_admin_role;
create role hlbs_user_role;
create role app_base_role;

grant connect to app_log_role;
grant connect to app_log_analyzer_role;
grant connect to app_user_role;
grant connect to app_admin_role;
grant connect to hlbs_user_role;
grant connect to app_base_role;

create user app_log_user01 identified by "";
create user app_user01 identified by "";
create user hlbs_user01 identified by "";
create user hlbs_aykut identified by "";
create user hlbs_aykut identified by "";

grant app_log_role to app_log_user01;
grant app_user_role to app_user01;
grant hlbs_user_role to hlbs_user01;
grant hlbs_user_role to hlbs_aykut;
create role lsports_writer_role;
create role lsports_reader_role;

create user apisports_main identified by ""
	default tablespace APP_MAIN
	quota unlimited on APP_MAIN
  quota unlimited on APP_MAIN_INDEX
	quota unlimited on APP_LOG;
grant connect, resource to apisports_main;
create role apisports_writer_role;
create role apisports_reader_role;
create role apisports_map_writer_role;
create role apisports_map_reader_role;
grant connect to apisports_writer_role;
grant connect to apisports_reader_role;
grant connect to apisports_map_writer_role;
grant connect to apisports_map_reader_role;
create user apisports_user01 identified by "";
grant app_base_role to apisports_user01;
grant apisports_writer_role to apisports_user01;
grant apisports_map_writer_role to apisports_user01;
grant lsports_reader_role to apisports_user01;

create user web_file identified by ""
	default tablespace APP_MAIN
	quota unlimited on APP_MAIN
  quota unlimited on APP_MAIN_INDEX
	quota unlimited on APP_LOG;
grant connect, resource to web_file;
create role web_file_writer_role;
create role web_file_reader_role;
grant connect to web_file_writer_role;
grant connect to web_file_reader_role;
create user web_file_user01 identified by "";
grant app_base_role to web_file_user01;
grant web_file_writer_role to web_file_user01;

create user web_config identified by ""
	default tablespace APP_MAIN
	quota unlimited on APP_MAIN
  quota unlimited on APP_MAIN_INDEX
	quota unlimited on APP_LOG;
grant connect, resource to web_config;
create role web_config_writer_role;
create role web_config_reader_role;
grant connect to web_config_writer_role;
grant connect to web_config_reader_role;

create user web_cache_user01 identified by "";
grant app_base_role to web_cache_user01;
grant web_file_reader_role to web_cache_user01;
grant web_config_reader_role to web_cache_user01;
grant lsports_reader_role to web_cache_user01;
grant apisports_reader_role to web_cache_user01;
grant apisports_map_reader_role to web_cache_user01;

create user web_config_user01 identified by "";
grant app_base_role to web_config_user01;
grant web_file_reader_role to web_config_user01;
grant web_config_reader_role to web_config_user01;

create user web_admin_user01 identified by "";
grant app_base_role to web_admin_user01;
grant web_file_writer_role to web_admin_user01;
grant web_config_writer_role to web_admin_user01;
grant lsports_reader_role to web_admin_user01;
grant apisports_reader_role to web_admin_user01;
grant apisports_map_writer_role to web_admin_user01;


create user web_service identified by ""
	default tablespace APP_MAIN
	quota unlimited on APP_MAIN
  quota unlimited on APP_MAIN_INDEX
	quota unlimited on APP_LOG;
grant connect, resource to web_service;

create role web_service_admin_role;
create role web_service_writer_role;
create role web_service_reader_role;
grant connect to web_service_admin_role;
grant connect to web_service_writer_role;
grant connect to web_service_reader_role;

create user web_user_service01 identified by "";
grant app_base_role to web_user_service01;
grant web_file_reader_role to web_user_service01;
grant web_config_reader_role to web_user_service01;
grant web_service_writer_role to web_user_service01;

create user web_service_admin01 identified by "";
grant app_base_role to web_service_admin01;
grant web_service_admin_role to web_service_admin01;
grant web_config_writer_role to web_service_admin01;
