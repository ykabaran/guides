----------------------------------------
-- CREATE ROLES/USERS
----------------------------------------

create user app_user identified by "8qUExgA7NSHEAu2U"
	default tablespace APP_MAIN
	quota unlimited on APP_MAIN
  quota unlimited on APP_MAIN_INDEX
	quota unlimited on APP_LOG;
grant connect, resource to app_user;

create role app_localized_data_writer;
create role app_localized_data_reader;

create role app_core_data_writer;
create role app_core_data_reader;

create role app_endpoint_data_creator;
create role app_endpoint_data_writer;
create role app_endpoint_data_reader;
create role app_endpoint_access_writer;
create role app_endpoint_access_reader;

create role app_auth_data_writer;
create role app_auth_data_reader;

create role app_user_data_writer;
create role app_user_data_reader;

create role app_data_change_writer;
create role app_data_change_reader;

create role app_diagnostics_data_writer;
create role app_diagnostics_data_reader;

create role app_core_admin;
grant app_data_change_writer, app_localized_data_writer, app_core_data_writer, app_endpoint_data_creator to app_core_admin;

create role app_endpoint;
grant app_data_change_writer, app_localized_data_reader, app_core_data_reader, app_endpoint_data_writer, app_endpoint_access_reader to app_endpoint;

create role app_manager_endpoint;
grant app_endpoint, app_endpoint_access_writer, app_diagnostics_data_writer to app_manager_endpoint;

create role app_auth_endpoint;
grant app_endpoint, app_auth_data_writer to app_auth_endpoint;

create role app_user_endpoint;
grant app_endpoint, app_user_data_writer to app_user_endpoint;


create user app_core_admin01 identified by "3JBh*0cVGb7RkU6G";
grant connect, app_core_admin to app_core_admin01;

create user app_manager_endpoint01 identified by "IQi@P80PVNp8qkmg";
grant connect, app_manager_endpoint to app_manager_endpoint01;

create user app_auth_endpoint01 identified by "F!3h34oJjqb*vX1*";
grant connect, app_auth_endpoint to app_auth_endpoint01;

create user app_user_endpoint01 identified by "mrL$2W!4%BP3nuWW";
grant connect, app_user_endpoint to app_user_endpoint01;

----------------------------------------
-- HINTS
----------------------------------------
/*
create table app_default_table (
  id varchar2(1023),
  create_date date default sysdate
);
ALTER TABLE app_default_table ADD CONSTRAINT pk_app_default_table PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_app_default_table_id ON app_default_table (id) tablespace APP_MAIN_INDEX;

create table partitioned_table (
  partition_date date not null
)
partition by range(partition_date)
interval (numtodsinterval(90,'day'))
(partition p0 values less than
  (to_date('2023-01-01','YYYY-MM-DD'))
)
ENABLE ROW MOVEMENT;

create table app_changing_table (
  sync_date number(32,0), -- optional, for data polled from 3rd parties
  change_tick number(32,0),
  change_date number(32,0)
);

 */

----------------------------------------
-- CREATE DATA_CHANGE_LOG
----------------------------------------

alter session set current_schema = app_log;

create table app_data_change_log_d1 (
  id varchar2(1023),
  table_name varchar2(1023),
  data_id varchar2(1023),
  change_data varchar2(32767),
  change_tick number(32,0),
  change_trace varchar2(32767),
  change_source varchar2(32767),
  partition_date date not null,
  create_date date default sysdate
)
nologging
partition by range(partition_date)
interval (numtodsinterval(1,'day'))
(partition p0 values less than
  (to_date('2023-01-01','YYYY-MM-DD'))
);
create table app_data_change_log_d7 (
  id varchar2(1023),
  table_name varchar2(1023),
  data_id varchar2(1023),
  change_data varchar2(32767),
  change_tick number(32,0),
  change_trace varchar2(32767),
  change_source varchar2(32767),
  partition_date date not null,
  create_date date default sysdate
)
nologging
partition by range(partition_date)
interval (numtodsinterval(7,'day'))
(partition p0 values less than
  (to_date('2023-01-01','YYYY-MM-DD'))
);
create table app_data_change_log_d30 (
  id varchar2(1023),
  table_name varchar2(1023),
  data_id varchar2(1023),
  change_data varchar2(32767),
  change_tick number(32,0),
  change_trace varchar2(32767),
  change_source varchar2(32767),
  partition_date date not null,
  create_date date default sysdate
)
nologging
partition by range(partition_date)
interval (numtodsinterval(30,'day'))
(partition p0 values less than
  (to_date('2023-01-01','YYYY-MM-DD'))
);
create table app_data_change_log_d90 (
  id varchar2(1023),
  table_name varchar2(1023),
  data_id varchar2(1023),
  change_data varchar2(32767),
  change_tick number(32,0),
  change_trace varchar2(32767),
  change_source varchar2(32767),
  partition_date date not null,
  create_date date default sysdate
)
nologging
partition by range(partition_date)
interval (numtodsinterval(90,'day'))
(partition p0 values less than
  (to_date('2023-01-01','YYYY-MM-DD'))
);
create table app_data_change_log_d180 (
  id varchar2(1023),
  table_name varchar2(1023),
  data_id varchar2(1023),
  change_data varchar2(32767),
  change_tick number(32,0),
  change_trace varchar2(32767),
  change_source varchar2(32767),
  partition_date date not null,
  create_date date default sysdate
)
nologging
partition by range(partition_date)
interval (numtodsinterval(180,'day'))
(partition p0 values less than
  (to_date('2023-01-01','YYYY-MM-DD'))
);
create table app_data_change_log_d360 (
  id varchar2(1023),
  table_name varchar2(1023),
  data_id varchar2(1023),
  change_data varchar2(32767),
  change_tick number(32,0),
  change_trace varchar2(32767),
  change_source varchar2(32767),
  partition_date date not null,
  create_date date default sysdate
)
nologging
partition by range(partition_date)
interval (numtodsinterval(360,'day'))
(partition p0 values less than
  (to_date('2023-01-01','YYYY-MM-DD'))
);

grant select on app_data_change_log_d1 to app_data_change_reader;
grant select on app_data_change_log_d7 to app_data_change_reader;
grant select on app_data_change_log_d30 to app_data_change_reader;
grant select on app_data_change_log_d90 to app_data_change_reader;
grant select on app_data_change_log_d180 to app_data_change_reader;
grant select on app_data_change_log_d360 to app_data_change_reader;
grant select,insert,update on app_data_change_log_d1 to app_data_change_writer;
grant select,insert,update on app_data_change_log_d7 to app_data_change_writer;
grant select,insert,update on app_data_change_log_d30 to app_data_change_writer;
grant select,insert,update on app_data_change_log_d90 to app_data_change_writer;
grant select,insert,update on app_data_change_log_d180 to app_data_change_writer;
grant select,insert,update on app_data_change_log_d360 to app_data_change_writer;

----------------------------------------
-- CREATE DIAGNOSTICS
----------------------------------------

create table app_diagnostics_log (
  id varchar2(1023),
  endpoint_id varchar2(1023),
  diagnostics_name varchar2(1023),
  diagnostics_data clob,
  diagnosis_data varchar2(32767),
  partition_date date not null,
  create_date date default sysdate
)
nologging
partition by range(partition_date)
interval (numtodsinterval(1,'day'))
(partition p0 values less than
  (to_date('2023-01-01','YYYY-MM-DD'))
);

grant select on app_diagnostics_log to app_diagnostics_data_reader;
grant select,insert,update on app_diagnostics_log to app_diagnostics_data_writer;

----------------------------------------
-- CREATE LOCALIZATION
----------------------------------------

alter session set current_schema = app_core;

create table app_localized_value (
  id varchar2(1023),
  namespace varchar2(1023),
  value_id varchar2(1023), -- the value's id in it's own namespace
  value_type varchar2(1023), -- string/file/template/json
  content_type varchar2(1023), -- text/plain, text/html
  value_en varchar2(32767),
  value_tr varchar2(32767),
  status varchar2(1023),  -- active, suspended, removed
  change_tick number(32,0),
  change_date number(32,0),
	create_date date default sysdate
);
ALTER TABLE app_localized_value ADD CONSTRAINT pk_app_localized_value PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

grant select on app_localized_value to app_localized_data_reader;
grant select,insert,update on app_localized_value to app_localized_data_writer;

----------------------------------------
-- CREATE CORE_DATA
----------------------------------------

create table app_permission (
	id varchar2(1023),
	name varchar2(1023),
  status varchar2(1023),  -- active, suspended, removed
  change_tick number(32,0),
  change_date number(32,0),
	create_date date default sysdate
);
ALTER TABLE app_permission ADD CONSTRAINT pk_app_permission PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

create table app_role (
	id varchar2(1023),
	name varchar2(1023),
	role_index number(4,0) not null,
  status varchar2(1023), -- active, suspended, removed
  change_tick number(32,0),
  change_date number(32,0),
	create_date date default sysdate
);
ALTER TABLE app_role ADD CONSTRAINT pk_app_role PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

create table app_role_permission (
	id varchar2(1023),
	role_id varchar2(1023) not null,
	permission_id varchar2(1023) not null,
	permission_params varchar2(32767), -- json
  status varchar2(1023), -- active, suspended, removed
  change_tick number(32,0),
  change_date number(32,0),
	create_date date default sysdate
);
ALTER TABLE app_role_permission ADD CONSTRAINT pk_app_role_permission PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

grant select on app_permission to app_core_data_reader;
grant select on app_role to app_core_data_reader;
grant select on app_role_permission to app_core_data_reader;
grant select,insert,update on app_permission to app_core_data_writer;
grant select,insert,update on app_role to app_core_data_writer;
grant select,insert,update on app_role_permission to app_core_data_writer;

----------------------------------------
-- CREATE ENDPOINT_DATA
----------------------------------------

create table app_endpoint (
	id varchar2(1023),
  status varchar2(1023), -- active, suspended, removed
  public_config varchar2(32767),
  private_config varchar2(32767),
  manager_config varchar2(32767), -- encrypted with manager_key
  auth_config varchar2(32767), -- encrypted with auth_key
  change_tick number(32,0),
  change_date number(32,0),
	create_date date default sysdate
);
ALTER TABLE app_endpoint ADD CONSTRAINT pk_app_endpoint PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

create table app_endpoint_access (
	id varchar2(1023),
	client_id varchar2(1023),
	server_id varchar2(1023),
	client_url varchar2(1023),
	server_url varchar2(1023),
  status varchar2(1023), -- active, suspended, removed
  security_level varchar2(32767), -- { req: hmac/aes/rsa_enc/rsa_sign, res: none/hmac/aes/rsa_enc/rsa_sign }
  client_public_config varchar2(32767),
  client_private_config varchar2(32767),
  server_public_config varchar2(32767),
  server_private_config varchar2(32767),
  manager_config varchar2(32767),
  change_tick number(32,0),
  change_date number(32,0),
	create_date date default sysdate
);
ALTER TABLE app_endpoint_access ADD CONSTRAINT pk_app_endpoint_access PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

grant select on app_endpoint to app_endpoint_data_reader;
grant select on app_endpoint_access to app_endpoint_access_reader;
grant select,update on app_endpoint to app_endpoint_data_writer;
grant select,insert,update on app_endpoint to app_endpoint_data_creator;
grant select,insert,update on app_endpoint_access to app_endpoint_access_writer;

----------------------------------------
-- CREATE AUTH_DATA
----------------------------------------

create table app_auth_key (
  id varchar2(1023),
	key_type varchar2(1023), -- session_token, auth_token
	key_roles varchar2(1023), -- key role subset
  security_level varchar2(1023), -- hmac/aes/rsa_enc/rsa_sign
	shared_secret varchar2(32767),
	encryption_key varchar2(32767),
	public_key varchar2(32767),
	private_key varchar2(32767),
	owner_endpoint_id varchar2(1023), -- which endpoint can sign using these
	target_endpoint_id varchar2(1023), -- null if not auth_token
	start_date number(32,0),
	end_date number(32,0),
	expire_date number(32,0),
	partition_date date not null,
	create_date date default sysdate
)
partition by range(partition_date)
interval (numtodsinterval(1,'day'))
(partition p0 values less than
  (to_date('2023-01-01','YYYY-MM-DD'))
);
ALTER TABLE app_auth_key ADD CONSTRAINT pk_app_auth_key PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

grant select on app_auth_key to app_auth_data_reader;
grant select,insert,update on app_auth_key to app_auth_data_writer;

----------------------------------------
-- CREATE USER_DATA
----------------------------------------

alter session set current_schema = app_user;

create table app_device (
	id varchar2(1023),
  status varchar2(1023), -- active, suspended, inactive
  usage_data varchar2(32767), -- ip addresses, users, user agents
  change_tick number(32,0),
  change_date number(32,0),
	partition_date date not null,
	create_date date default sysdate
)
partition by range(partition_date)
interval (numtodsinterval(30,'day'))
(partition p0 values less than
  (to_date('2023-01-01','YYYY-MM-DD'))
)
ENABLE ROW MOVEMENT;
ALTER TABLE app_device ADD CONSTRAINT pk_app_device PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

create table app_user (
	id varchar2(1023),
	username varchar2(1023) not null,
	name varchar2(1023),
	email varchar2(1023),
	auth_data varchar2(32767), -- login types, password, 2fa token, email confirmation token; encrypted with user_key from private_config
  status varchar2(1023), -- active, suspended, removed
  change_tick number(32,0),
  change_date number(32,0),
	create_date date default sysdate
);
ALTER TABLE app_user ADD CONSTRAINT pk_app_user PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE UNIQUE INDEX ind_app_user_username ON app_user (username) tablespace APP_MAIN_INDEX;

create table app_session (
	id varchar2(1023),
	device_id varchar2(1023) not null,
	user_id varchar2(1023),
  auth_data varchar2(32767), -- roles, role_params, refresh keys; encrypted with session_key
  expiration_date number(32,0),
  status varchar2(1023), -- active, suspended, expired, ended
  change_tick number(32,0),
  change_date number(32,0),
  partition_date date not null,
	create_date date default sysdate
)
partition by range(partition_date)
interval (numtodsinterval(30,'day'))
(partition p0 values less than
  (to_date('2023-01-01','YYYY-MM-DD'))
)
ENABLE ROW MOVEMENT;
ALTER TABLE app_session ADD CONSTRAINT pk_app_session PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_app_session_expiration_date ON app_session (expiration_date) tablespace APP_MAIN_INDEX;

grant select on app_device to app_user_data_reader;
grant select on app_user to app_user_data_reader;
grant select on app_session to app_user_data_reader;
grant select,insert,update on app_device to app_user_data_writer;
grant select,insert,update on app_user to app_user_data_writer;
grant select,insert,update on app_session to app_user_data_writer;








