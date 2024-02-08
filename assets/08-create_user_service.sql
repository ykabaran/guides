create user USER_SERVICE identified by "SwhX7Wx5yuOq732T"
  default tablespace APP_MAIN
  quota unlimited on APP_MAIN
  quota unlimited on APP_MAIN_INDEX;
grant connect, resource to USER_SERVICE;

create table app_user (
	user_id varchar2(1023),
	type varchar2(1023),
	status varchar2(1023), -- ACTIVE, DISABLED,
	data varchar2(32767), -- name, address, phone, etc
	email varchar2(1023), -- maybe null for affiliate-only users
	auth_data varchar2(32767), -- password_hash info and such
	last_login_date number(32,0),
	create_date number(32,0),
	create_ts timestamp default systimestamp,
	CONSTRAINT pk_app_user PRIMARY KEY (user_id)
	  using index tablespace APP_MAIN_INDEX
);

create table app_client_user (
	user_id varchar2(1023),
	client_id varchar2(1023),
	client_user_id varchar2(1023)
);

create unique index ind_unq_app_client_user_id
  on app_client_user(client_id, client_user_id)
  tablespace APP_MAIN_INDEX;

create table app_user_account (
	user_id varchar2(1023),
	account_id varchar2(1023),
	last_use_date number(32,0),
	create_date number(32,0),
	create_ts timestamp default systimestamp
);

create index ind_app_user_account_user_id
  on app_user_account(user_id)
	tablespace app_main_index;

create index ind_app_user_account_account_id
  on app_user_account(account_id)
	tablespace app_main_index;

create table app_user_session (
	session_id varchar2(1023),
	session_token varchar2(1023),
	user_id varchar2(1023),
	session_source varchar2(1023), -- USER_LOGIN, AFFILIATE_LOGIN
	session_max_age number(32,0),
	status varchar2(1023), -- ACTIVE, CLOSED
	data varchar2(32767), -- maybe affiliate_id
	start_date number(32,0),
	last_active_date number(32,0),
	end_date number(32,0),
	end_reason varchar2(1023), -- USER_LOGGED_OUT, PASSWORD_CHANGED, EXPIRED
	create_date number(32,0),
	create_ts timestamp default systimestamp,
	CONSTRAINT pk_app_user_session PRIMARY KEY (session_id)
	  using index tablespace app_main_index
)
partition by range(create_ts)
interval (numtodsinterval(30,'day'))
(partition p0 values less than
  (to_date('2021-01-01','YYYY-MM-DD'))
);

create index ind_app_user_session_user_id
  on app_user_session (user_id)
  tablespace APP_MAIN_INDEX;

create index ind_app_user_session_create_date
  on app_user_session (create_date)
  tablespace APP_MAIN_INDEX;

create index ind_app_user_session_status
  on app_user_session (status)
  tablespace APP_MAIN_INDEX;

GRANT SELECT, INSERT, UPDATE ON app_user TO app_user_role;
GRANT SELECT, INSERT, UPDATE ON app_client_user TO app_user_role;
GRANT SELECT, INSERT, UPDATE ON app_user_account TO app_user_role;
GRANT SELECT, INSERT, UPDATE ON app_user_session TO app_user_role;