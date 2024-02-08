create user CRYPTO_SERVICE identified by "x93GdLTfbxMjl3YH"
  default tablespace APP_MAIN
  quota unlimited on APP_MAIN
  quota unlimited on APP_MAIN_INDEX;
grant connect, resource to CRYPTO_SERVICE;

create table blockchain_network_service (
  service_id varchar2(1023),
	network_id varchar2(1023),
	client_id varchar2(1023),
	name varchar2(1023),
	status varchar2(1023), -- ONLINE, OFFLINE, DISABLED,
	data varchar2(32767),
	create_ts timestamp default systimestamp,
	CONSTRAINT pk_blockchain_network_service PRIMARY KEY (service_id)
);

create table wallet_vault_service (
	vault_id varchar2(1023),
	name varchar2(1023),
	status varchar2(1023), -- ONLINE, OFFLINE, DISABLED, DELETED, LOST, COMPROMISED
	client_id varchar2(1023),
	create_date number(32,0),
	create_ts timestamp default systimestamp,
	CONSTRAINT pk_wallet_vault PRIMARY KEY (vault_id)
);

create table account_address (
	address_id varchar2(1023),
	address varchar2(1023), -- the public address
	account_id varchar2(1023),
	network_id varchar2(1023),
	network_service_id varchar2(1023), -- service tracking the address
	account_service_id varchar2(1023), -- service tracking the account
	type varchar2(1023), -- HOT, COLD
	data varchar2(32767), -- { type, etc }
	status varchar2(1023), -- ACTIVE, DISABLED
	create_date number(32,0),
	create_ts timestamp default systimestamp,
	CONSTRAINT pk_account_address PRIMARY KEY (address_id)
	  using index tablespace APP_MAIN_INDEX
);

create index ind_account_address_address
  on account_address (address)
  tablespace APP_MAIN_INDEX;

create index ind_account_address_account_id
  on account_address (account_id)
  tablespace APP_MAIN_INDEX;

create table wallet_address_key (
	key_id varchar2(1023),
	address_id varchar2(1023),
	status varchar2(1023), -- ONLINE, DELETED, COMPROMISED, GONE_FOREVER
	name varchar2(1023), -- PRIVATE_KEY, REDEEM_SCRIPT, WITNESS_SCRIPT, NFT_*_SECRET, etc
	key_secret varchar2(32767),
	total_shards number(2,0),
	required_shards number(2,0),
	create_date number(32,0),
	create_ts timestamp default systimestamp,
	CONSTRAINT pk_wallet_address_key PRIMARY KEY (key_id)
	  using index tablespace APP_MAIN_INDEX
);

create index ind_wallet_address_key_address_id
  on wallet_address_key (address_id)
  tablespace APP_MAIN_INDEX;

create table wallet_address_key_shard (
	shard_id varchar2(1023),
	key_id varchar2(1023),
	shard_num number(32,0),
	status varchar2(1023), -- ONLINE, DELETED, COMPROMISED, GONE_FOREVER
	vault_id varchar2(1023),
	vault_shard_secret varchar2(32767),
	shard_secret varchar2(32767),
	create_date number(32,0),
	create_ts timestamp default systimestamp,
	CONSTRAINT pk_wallet_address_key_shard PRIMARY KEY (shard_id)
	  using index tablespace APP_MAIN_INDEX
);

create index ind_wallet_address_key_shard
  on wallet_address_key_shard (key_id)
  tablespace APP_MAIN_INDEX;

create table account_address_update (
  update_id varchar2(1023),
	address_id varchar2(1023),
  currency_id varchar2(1023),
	address_update_id varchar2(1023), -- update_id on btc_service, eth_service, etc
	address_update_data varchar2(32767),
	address_update_date number(32,0),
	transaction_update_id varchar2(1023), -- update_id on account_service
	transaction_update_data varchar2(32767),
	transaction_update_date number(32,0),
	create_date number(32,0),
	create_ts timestamp default systimestamp,
	CONSTRAINT pk_account_address_update PRIMARY KEY (update_id)
	  using index tablespace APP_MAIN_INDEX
)
partition by range(create_ts)
interval (numtodsinterval(120,'day'))
(partition p0 values less than
  (to_date('2021-01-01','YYYY-MM-DD'))
);

create index ind_account_address_update_address_id
  on account_address_update (address_id)
  tablespace APP_MAIN_INDEX;

GRANT SELECT ON blockchain_network_service TO app_user_role;
GRANT SELECT ON wallet_vault_service TO app_user_role;
GRANT SELECT, INSERT, UPDATE ON account_address TO app_user_role;
GRANT SELECT, INSERT, UPDATE ON wallet_address_key TO app_user_role;
GRANT SELECT, INSERT, UPDATE ON wallet_address_key_shard TO app_user_role;
GRANT SELECT, INSERT ON account_address_update TO app_user_role;
GRANT INSERT, UPDATE ON blockchain_network_service TO app_admin_role;
GRANT INSERT, UPDATE ON wallet_vault_service TO app_admin_role;