
create user db_admin identified by "bGhNspHK82eCyxPT"
  default tablespace APP_LOG
  quota unlimited on APP_LOG;

create user app_log identified by "4vF8uQJqWXu5sCQr"
  default tablespace APP_LOG
  quota unlimited on APP_LOG;

create user app_core identified by "Qm8cTd333AVn3nrb"
  default tablespace APP_CORE
  quota unlimited on APP_CORE;

-- create user app_service identified by "..."
--   default tablespace APP_MAIN
--   quota unlimited on APP_MAIN
--   quota unlimited on APP_MAIN_INDEX;

-- grant connect, resource to app_service;

-- alter user app_service quota unlimited on app_main_index;

grant connect, dba to db_admin;
grant connect, resource to app_log;
grant connect, resource to app_core;

create role app_log_role;
create role app_user_role;
create role app_admin_role;

grant connect to app_log_role;
grant connect to app_user_role;
grant app_user_role to app_admin_role;

create user app_log_user01 identified by "6avTI0mIw1BJ4gvP";
create user app_user01 identified by "1qrrzfeo3TAmnQ4x";
create user app_admin01 identified by "vZo7kFaT9GYsStGO";

grant app_log_role to app_log_user01;
grant app_user_role to app_admin_role;
grant app_user_role to app_user01;
grant app_admin_role to app_admin01;

-- drop user app_log_user01;
-- drop user app_user01;
-- drop user app_admin01;
-- drop role app_admin_role;
-- drop role app_user_role;
-- drop role app_log_role;