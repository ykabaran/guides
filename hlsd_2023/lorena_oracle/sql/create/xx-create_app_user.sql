----------------------------------------
-- CREATE ROLES/USERS
----------------------------------------

create user app_user identified by ""
	default tablespace APP_MAIN
	quota unlimited on APP_MAIN
  quota unlimited on APP_MAIN_INDEX
	quota unlimited on APP_LOG;
grant connect, resource to app_user;



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
	role_data varchar2(32767), -- roles, role_params

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE app_user ADD CONSTRAINT pk_app_user PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE UNIQUE INDEX ind_app_user_username ON app_user (username) tablespace APP_MAIN_INDEX;

create table app_session (
	id varchar2(1023),
	device_id varchar2(1023) not null,
	user_id varchar2(1023),
  auth_data varchar2(32767), -- refresh keys; encrypted with session_key
  role_data varchar2(32767), -- roles, role_params
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

app_object/get
	{
		filter: {},
		view: {}
	}
app_object/set
	{
		id,
		version.
		item: {}
	}

user/get
	{
		filter: {},
		view: {}
	}
user/set
	{
		id,
		version.
		item: {},
		user_data: [{
			id,
			version,
			item: {}
		}]
	}








