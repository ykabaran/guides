
create user app_user identified by ""
	default tablespace APP_MAIN
	quota unlimited on APP_MAIN
  quota unlimited on APP_MAIN_INDEX
	quota unlimited on APP_LOG;
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
  (to_date('2024-01-01','YYYY-MM-DD'))
)
ENABLE ROW MOVEMENT
tablespace app_main;
ALTER TABLE app_device ADD CONSTRAINT pk_app_device PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

create table app_user (
	id number(32,0),
	username varchar2(1023) not null,
	name varchar2(1023),
	email varchar2(1023),
  parent_id number(32,0),

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
  (to_date('2024-01-01','YYYY-MM-DD'))
)
ENABLE ROW MOVEMENT
tablespace app_main;
ALTER TABLE app_user ADD CONSTRAINT pk_app_user PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE UNIQUE INDEX ind_app_user_username ON app_user (username) tablespace APP_MAIN_INDEX;

create table app_session (
	id number(32,0),
	device_id number(32,0),
	user_id number(32,0),

  auth_data varchar2(32767), -- refresh keys, csrf tokens; encrypted with session_key
  role_data varchar2(32767), -- roles with params
  csrf_data varchar2(32767), -- csrf tokens
  expiration_date number(32,0),

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0),

  partition_date date not null
)
partition by range(partition_date)
interval (numtodsinterval(30,'day'))
(partition p0 values less than
  (to_date('2024-01-01','YYYY-MM-DD'))
)
ENABLE ROW MOVEMENT
tablespace app_main;
ALTER TABLE app_session ADD CONSTRAINT pk_app_session PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_app_session_expiration_date ON app_session (expiration_date) tablespace APP_MAIN_INDEX;

create table data_change_d7 (
  id number(32,0),
  table_id number(32,0) not null,
  data_id number(32,0) not null,
  parent_id number(32,0),
  column_name varchar2(1023),
  
  change_type varchar2(1023) not null,
  before_value varchar2(32767),
  after_value varchar2(32767),
  source_data varchar2(32767),

  version number(16,0) not null,
  change_date number(32,0) not null,
  partition_date date default sysdate not null 
)
partition by range(partition_date)
interval (numtodsinterval(7,'day'))
(partition p0 values less than
  (to_date('2024-01-01','YYYY-MM-DD'))
)
pctfree 0
nologging
tablespace app_log;
ALTER TABLE data_change_d7 ADD CONSTRAINT pk_data_change_d7 PRIMARY KEY (id) USING INDEX TABLESPACE app_log;
CREATE INDEX ind_data_change_d7_change_date ON data_change_d7 (change_date) tablespace app_log;
CREATE INDEX ind_data_change_d7_data_id ON data_change_d7 (data_id) tablespace app_log;


create table data_change_d30 (
  id number(32,0),
  table_id number(32,0) not null,
  data_id number(32,0) not null,
  parent_id number(32,0),
  column_name varchar2(1023),
  
  change_type varchar2(1023) not null,
  before_value varchar2(32767),
  after_value varchar2(32767),
  source_data varchar2(32767),

  version number(16,0) not null,
  change_date number(32,0) not null,
  partition_date date default sysdate not null 
)
partition by range(partition_date)
interval (numtodsinterval(30,'day'))
(partition p0 values less than
  (to_date('2024-01-01','YYYY-MM-DD'))
)
pctfree 0
nologging
tablespace app_log;
ALTER TABLE data_change_d30 ADD CONSTRAINT pk_data_change_d30 PRIMARY KEY (id) USING INDEX TABLESPACE app_log;
CREATE INDEX ind_data_change_d30_change_date ON data_change_d30 (change_date) tablespace app_log;
CREATE INDEX ind_data_change_d30_data_id ON data_change_d30 (data_id) tablespace app_log;


create table data_change_d300 (
  id number(32,0),
  table_id number(32,0) not null,
  data_id number(32,0) not null,
  parent_id number(32,0),
  column_name varchar2(1023),
  
  change_type varchar2(1023) not null,
  before_value varchar2(32767),
  after_value varchar2(32767),
  source_data varchar2(32767),

  version number(16,0) not null,
  change_date number(32,0) not null,
  partition_date date default sysdate not null 
)
partition by range(partition_date)
interval (numtodsinterval(300,'day'))
(partition p0 values less than
  (to_date('2024-01-01','YYYY-MM-DD'))
)
pctfree 0
nologging
tablespace app_log;
ALTER TABLE data_change_d300 ADD CONSTRAINT pk_data_change_d300 PRIMARY KEY (id) USING INDEX TABLESPACE app_log;
CREATE INDEX ind_data_change_d300_change_date ON data_change_d300 (change_date) tablespace app_log;
CREATE INDEX ind_data_change_d300_data_id ON data_change_d300 (data_id) tablespace app_log;

create role app_user_reader;
create role app_user_writer;
create role app_user_deleter;

grant select on app_device to app_user_reader;
grant select on app_user to app_user_reader;
grant select on app_session to app_user_reader;
grant select on data_change_d7 to app_user_reader;
grant select on data_change_d30 to app_user_reader;
grant select on data_change_d300 to app_user_reader;

grant select,insert,update on app_device to app_user_writer;
grant select,insert,update on app_user to app_user_writer;
grant select,insert,update on app_session to app_user_writer;
grant select,insert,update on data_change_d7 to app_user_writer;
grant select,insert,update on data_change_d30 to app_user_writer;
grant select,insert,update on data_change_d300 to app_user_writer;

grant select,insert,update,delete on app_device to app_user_deleter;
grant select,insert,update,delete on app_user to app_user_deleter;
grant select,insert,update,delete on app_session to app_user_deleter;
