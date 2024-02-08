create user NICOBET_BRIDGE identified by "s6CY1N8hq9zRioMa"
  default tablespace APP_MAIN
  quota unlimited on APP_MAIN
  quota unlimited on APP_MAIN_INDEX;
grant connect, resource to NICOBET_BRIDGE;

create table access_token (
  token varchar2(1023),
  client_id varchar2(1023),
  user_id varchar2(1023),
  status varchar2(1023), -- ACTIVE, EXPIRED, REDEEMED
  session_id varchar2(1023),
  trace_id varchar2(1023),
	create_date number(32,0),
	create_ts timestamp default systimestamp,
	CONSTRAINT pk_access_token PRIMARY KEY (token)
	  using index tablespace app_main_index
)
partition by range(create_ts)
interval (numtodsinterval(7,'day'))
(partition p0 values less than
  (to_date('2021-01-01','YYYY-MM-DD'))
);

create table user_session (
  session_id varchar2(1023),
  user_id varchar2(1023),
  status varchar2(1023), -- ACTIVE, ENDED, ERRORED
  trace_id varchar2(1023),
  create_date number(32,0),
  end_date number(32,0),
	create_ts timestamp default systimestamp,
	CONSTRAINT pk_user_session PRIMARY KEY (session_id)
	  using index tablespace app_main_index
)
partition by range(create_ts)
interval (numtodsinterval(120,'day'))
(partition p0 values less than
  (to_date('2021-01-01','YYYY-MM-DD'))
);

create index ind_user_session_user_id
  on user_session (user_id)
  tablespace APP_MAIN_INDEX;

create index ind_user_session_create_date
  on user_session (create_date)
  tablespace APP_MAIN_INDEX;

create index ind_user_session_status
  on user_session (status)
  tablespace APP_MAIN_INDEX;

create table session_transaction (
  transaction_id varchar2(1023),
  session_id varchar2(1023),
  nico_tra_id varchar2(1023),
  type varchar2(1023), -- IN, OUT
  status varchar2(1023), -- COMPLETED, ERRORED
  status_data varchar2(32767),
  currency varchar2(1023),
  amount number(32,0),
  amount_scale number(2,0),
  create_date number(32,0),
  update_date number(32,0),
	create_ts timestamp default systimestamp,
	CONSTRAINT pk_session_transaction PRIMARY KEY (transaction_id)
	  using index tablespace app_main_index
)
partition by range(create_ts)
interval (numtodsinterval(120,'day'))
(partition p0 values less than
  (to_date('2021-01-01','YYYY-MM-DD'))
);

create index ind_session_transaction_session_id
  on session_transaction (session_id)
  tablespace APP_MAIN_INDEX;

create index ind_session_transaction_nico_tra_id
  on session_transaction (nico_tra_id)
  tablespace APP_MAIN_INDEX;

create table session_transaction_update (
  update_id varchar2(1023),
  transaction_id varchar2(1023),
  type varchar2(1023), -- CREATE, ERROR, COMPLETE
  update_data varchar2(32767),
  trace_id varchar2(1023),
  create_date number(32,0),
	create_ts timestamp default systimestamp,
	CONSTRAINT pk_session_transaction_update PRIMARY KEY (update_id)
	  using index tablespace app_main_index
)
partition by range(create_ts)
interval (numtodsinterval(30,'day'))
(partition p0 values less than
  (to_date('2021-01-01','YYYY-MM-DD'))
);

create index ind_session_transaction_update_transaction_id
  on session_transaction_update (transaction_id)
  tablespace APP_MAIN_INDEX;

GRANT SELECT, INSERT, UPDATE ON access_token TO app_user_role;
GRANT SELECT, INSERT, UPDATE ON user_session TO app_user_role;
GRANT SELECT, INSERT, UPDATE ON session_transaction TO app_user_role;
GRANT SELECT, INSERT ON session_transaction_update TO app_user_role;