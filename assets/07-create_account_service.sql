create user ACCOUNT_SERVICE identified by "m4S0MV5kGbEDubdy"
  default tablespace APP_MAIN
  quota unlimited on APP_MAIN
  quota unlimited on APP_MAIN_INDEX;
grant connect, resource to ACCOUNT_SERVICE;

create table account (
	account_id varchar2(1023),
	owner varchar2(1023),
	name varchar2(1023),
	type varchar2(1023), -- GAME_ACCOUNT, AFFILIATE_ACCOUNT, FEE_ACCOUNT, DEPOSIT_ACCOUNT
	status varchar2(1023), -- ACTIVE, DISABLED, CLOSED
	data varchar2(32767),
	create_date number(32,0),
	create_ts timestamp default systimestamp,
	CONSTRAINT pk_account PRIMARY KEY (account_id)
	  using index tablespace APP_MAIN_INDEX
);

create table account_balance (
	balance_id varchar2(1023),
	account_id varchar2(1023),
	currency_id varchar2(1023),
	name varchar2(1023), -- unique
	type varchar2(1023), -- IN_GAME_BALANCE, PRIMARY_BALANCE, CLIENT_BALANCE
	status varchar2(1023), -- ACTIVE, CLOSED, DISABLED
	data varchar2(32767),
	balance number(32,0), -- positive for most balances, some may go negative (like affiliate balances)
	pending_in number(32,0), -- positive
	pending_out number(32,0), -- positive
	total_in number(32,0), -- positive
	total_out number(32,0), -- positive
	update_id varchar2(1023),
	create_date number(32,0),
	create_ts timestamp default systimestamp,
	CONSTRAINT pk_account_balance PRIMARY KEY (balance_id)
	  using index tablespace APP_MAIN_INDEX
);

create index ind_account_balance_account_id
	on account_balance (account_id)
	tablespace app_main_index;

create table account_asset (
	asset_id varchar2(1023),
	account_id varchar2(1023),
	currency_id varchar2(1023),
	name varchar2(1023), -- unique
	type varchar2(1023), -- VIDEO_POKER_BONUS, UTXO, NFT?
	status varchar2(1023), -- PENDING, AVAILABLE, USING, USED, DELETED
	data varchar2(32767),
	update_id varchar2(1023),
	create_date number(32,0),
	create_ts timestamp default systimestamp,
	CONSTRAINT pk_account_asset PRIMARY KEY (asset_id)
	  using index tablespace APP_MAIN_INDEX
);

create index ind_account_asset_account_id
	on account_asset (account_id)
	tablespace app_main_index;

create table account_transaction (
	transaction_id varchar2(1023),
	owner varchar2(1023),
	reason varchar2(1023), -- WALLET_DEPOSIT, WALLET_WITHDRAWAL, INTERNAL_ACCOUNTING, MOVE_HOT/COLD_*_TO_HOT/COLD_*
	type varchar2(1023), -- USER_TO_USER, USER_EX_USER, USER_TO_US, US_TO_USER, US_TO_US, USER_EX_US, USER_TO_AFFILIATE, AFFILIATE_TO_USER
	status varchar2(1023), -- PENDING, PROCESSING, WAITING_NETWORK, FINALIZED, CANCELLED
	data varchar2(32767), -- { confirmations }, { processingError }, { cancellationInfo }, etc
	update_id varchar2(1023),
	create_date number(32,0),
	create_ts timestamp default systimestamp,
	CONSTRAINT pk_account_transaction PRIMARY KEY (transaction_id)
	  using index tablespace APP_MAIN_INDEX
)
partition by range(create_ts)
interval (numtodsinterval(120,'day'))
(partition p0 values less than
  (to_date('2021-01-01','YYYY-MM-DD'))
);

create table account_transaction_unit (
	transaction_unit_id varchar2(1023),
	owner varchar2(1023),
	root_transaction_unit_id varchar2(1023),
	transaction_id varchar2(1023),
	currency_id varchar2(1023),
	reason varchar2(1023), -- DEPOSIT, WITHDRAWAL, FEE, COMMISSION, PLAY_GAME, etc
	type varchar2(1023), -- INPUT_BALANCE, OUTPUT_BALANCE, INPUT_ASSET, OUTPUT_ASSET
	target_type varchar2(1023), -- OUR_WALLET, USER_EXTERNAL, COLD_EXTERNAL, USER_BALANCE, AFFILIATE_BALANCE, AFFILIATE_FEE, etc
	status varchar2(1023), -- PENDING, CONFIRMING, CONFIRMED, CANCELLED
	data varchar2(32767), -- maybe target data like the external address, status data like number of confirmations, or error
	account_id varchar2(1023), -- maybe null for non EXTERNAL targets
	balance_id varchar2(1023), -- NULL for ASSET types
	value number(32,0), -- positive or null for asset types
	balance_snapshot number(32,0), -- balance at the time of transaction
	asset_id varchar2(1023), -- null for non-ASSET types
	update_id varchar2(1023),
	create_date number(32,0),
	create_ts timestamp default systimestamp,
	CONSTRAINT pk_account_transaction_unit PRIMARY KEY (transaction_unit_id)
	  using index tablespace APP_MAIN_INDEX
)
partition by range(create_ts)
interval (numtodsinterval(120,'day'))
(partition p0 values less than
  (to_date('2021-01-01','YYYY-MM-DD'))
);

create index ind_account_transaction_unit_transaction_id
	on account_transaction_unit (transaction_id)
	tablespace app_main_index;

create index ind_account_transaction_unit_account_id
	on account_transaction_unit (account_id)
	tablespace app_main_index;

create table account_transaction_update (
  update_id varchar2(1023),
	owner varchar2(1023),
	transaction_id varchar2(1023),
	reason varchar2(1023), -- USER_INITIATED_TRANSFER, BLOCKCHAIN_CONFIRMATION, etc
	type varchar2(1023), -- CREATE, UPDATE, FINALIZE, CANCEL, etc
	data varchar2(32767), -- { before, after }
	create_date number(32,0),
	create_ts timestamp default systimestamp,
	CONSTRAINT pk_account_transaction_update PRIMARY KEY (update_id)
	  using index tablespace APP_MAIN_INDEX
)
partition by range(create_ts)
interval (numtodsinterval(30,'day'))
(partition p0 values less than
  (to_date('2021-01-01','YYYY-MM-DD'))
);

create index ind_account_transaction_update_transaction_id
	on account_transaction_update (transaction_id)
	tablespace app_main_index;

GRANT SELECT, INSERT, UPDATE ON account TO app_user_role;
GRANT SELECT, INSERT, UPDATE ON account_balance TO app_user_role;
GRANT SELECT, INSERT, UPDATE ON account_asset TO app_user_role;
GRANT SELECT, INSERT, UPDATE ON account_transaction TO app_user_role;
GRANT SELECT, INSERT, UPDATE ON account_transaction_unit TO app_user_role;
GRANT SELECT, INSERT, UPDATE ON account_transaction_update TO app_user_role;