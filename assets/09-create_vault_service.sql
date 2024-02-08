create user VAULT_SERVICE identified by "avk5Da7ieWebFc2V"
  default tablespace APP_MAIN
  quota unlimited on APP_MAIN
  quota unlimited on APP_MAIN_INDEX;
grant connect, resource to VAULT_SERVICE;

create table vault (
  shard_id varchar2(1023),
  client_id varchar2(1023),
  status varchar2(1023), -- ACTIVE, RESTRICTED, DISABLED, DELETED
  secret varchar2(1023),
  value varchar2(32767),
	create_date number(32,0),
	create_ts timestamp default systimestamp,
	CONSTRAINT pk_vault PRIMARY KEY (shard_id)
	  using index tablespace app_main_index
);

create table vault_access (
  client_id varchar2(1023),
  request_id varchar2(1023),
  request_date number(32,0),
  shard_id varchar2(1023),
  status varchar2(1023), -- SUCCESS, FAILED
  type varchar2(1023), -- CREATE, READ, DELETE
  data varchar2(32767),
  req_data varchar2(32767),
  response_data varchar2(32767),
	create_date number(32,0),
	create_ts timestamp default systimestamp
)
partition by range(create_ts)
interval (numtodsinterval(7,'day'))
(partition p0 values less than
  (to_date('2021-05-01','YYYY-MM-DD'))
);

create index ind_vault_access_shard_id
  on vault_access (shard_id)
	tablespace app_main_index;

create index ind_vault_access_client_id
  on vault_access (client_id)
	tablespace app_main_index;

GRANT SELECT, INSERT, UPDATE ON vault TO app_user_role;
GRANT SELECT, INSERT ON vault_access TO app_user_role;