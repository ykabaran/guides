create user app_user identified by ""
	default tablespace APP_MAIN
	quota unlimited on APP_MAIN
  quota unlimited on APP_MAIN_INDEX;
grant connect, resource to app_user;

alter session set current_schema = app_user;

create table app_device (
	id number(32,0),
  usage_data varchar2(32767), -- ip addresses, users, user agents

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0),

	partition_date date not null
)
partition by range(partition_date)
interval (numtodsinterval(30,'day'))
(partition p0 values less than
  (to_date('2025-01-01','YYYY-MM-DD'))
)
ENABLE ROW MOVEMENT;
ALTER TABLE app_device ADD CONSTRAINT pk_app_device PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

create table app_user (
	id number(32,0),
  parent_id number(32,0),
	username varchar2(1023) not null,
	name varchar2(1023),
	email varchar2(1023),

	auth_data varchar2(32767), -- login types, password, 2fa token, email confirmation token; encrypted with user_key from private_config
	role_data varchar2(32767), -- roles with params

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0),

  partition_date date not null
)
partition by range(partition_date)
interval (numtodsinterval(30,'day'))
(partition p0 values less than
  (to_date('2025-01-01','YYYY-MM-DD'))
)
ENABLE ROW MOVEMENT;
ALTER TABLE app_user ADD CONSTRAINT pk_app_user PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE UNIQUE INDEX unq_app_user_username ON app_user (username) tablespace APP_MAIN_INDEX;

create table app_session (
	id number(32,0),
	device_id number(32,0) not null,
  app_id number(32,0) not null,
	user_id number(32,0),
  ref_id varchar2(1023),

  auth_data varchar2(32767), -- refresh keys, csrf tokens; encrypted with session_key
  role_data varchar2(32767), -- roles with params
  extra_data varchar2(32767), -- extra session information in plain json
  csrf_data varchar2(32767), -- csrf tokens
  expiration_date number(32,0) not null,

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0),

  partition_date date not null
)
partition by range(partition_date)
interval (numtodsinterval(30,'day'))
(partition p0 values less than
  (to_date('2025-01-01','YYYY-MM-DD'))
)
ENABLE ROW MOVEMENT;
ALTER TABLE app_session ADD CONSTRAINT pk_app_session PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_app_session_expiration_date ON app_session (expiration_date) tablespace APP_MAIN_INDEX;
CREATE UNIQUE INDEX unq_app_session_ref_id ON app_session (ref_id) tablespace APP_MAIN_INDEX;

create table app_session_event (
  id number(32,0),
  session_id number(32,0),

  type varchar2(1023), -- user logged in, user heartbeat, user played game
  data varchar2(32767),

  create_date number(32,0),
  partition_date date not null
)
partition by range(partition_date)
interval (numtodsinterval(7,'day'))
(partition p0 values less than
  (to_date('2025-01-01','YYYY-MM-DD'))
)
pctfree 0
nologging;
ALTER TABLE app_session_event ADD CONSTRAINT pk_app_session_event PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_app_session_event_session ON app_session_event (session_id) tablespace APP_MAIN_INDEX;
CREATE INDEX ind_app_session_event_date ON app_session_event (create_date) tablespace APP_MAIN_INDEX;

create role app_user_reader;
create role app_user_writer;
create role app_user_deleter;

grant select on app_device to app_user_reader;
grant select on app_user to app_user_reader;
grant select on app_session to app_user_reader;

grant select,insert,update on app_device to app_user_writer;
grant select,insert,update on app_user to app_user_writer;
grant select,insert,update on app_session to app_user_writer;

grant select,insert,update,delete on app_device to app_user_deleter;
grant select,insert,update,delete on app_user to app_user_deleter;
grant select,insert,update,delete on app_session to app_user_deleter;
