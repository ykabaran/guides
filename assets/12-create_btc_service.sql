create user BTC_SERVICE identified by "6B499oz33FoEUuM8"
  default tablespace APP_MAIN
  quota unlimited on APP_MAIN
  quota unlimited on APP_MAIN_INDEX;
grant connect, resource to BTC_SERVICE;

create table blockchain_block (
	block_hash varchar2(1023),
	status varchar2(1023), -- ACTIVE, ABANDONED
	confirmations number(32,0),
	block_height number(32,0),
	prev_block_hash varchar2(1023),
	next_block_hash varchar2(1023),
	block_merkle_root varchar2(1023),
	block_time number(32,0),
	block_median_time number(32,0),
	block_version varchar2(1023),
	num_transactions number(32,0),
	block_difficulty varchar2(1023),
	block_chainwork varchar2(1023),
	create_date number(32,0),
	create_ts timestamp default systimestamp,
	CONSTRAINT pk_blockchain_block PRIMARY KEY (block_hash)
	  using index tablespace app_main_index
);

create index ind_blockchain_block_block_height
  on blockchain_block (block_height)
	tablespace app_main_index;

create table blockchain_address (
	address varchar2(1023),
	status varchar2(1023), -- ACTIVE, DISABLED
	total_received number(32,0),
	total_sent number(32,0),
	balance number(32,0),
	unconfirmed_balance number(32,0),
	create_date number(32,0),
	create_ts timestamp default systimestamp,
	CONSTRAINT pk_blockchain_address PRIMARY KEY (address)
	  using index tablespace app_main_index
);

create table client_address (
  client_id varchar2(1023),
	address varchar2(1023),
	status varchar2(1023), -- ACTIVE, DISABLED
	create_date number(32,0),
	create_ts timestamp default systimestamp
);

create index ind_client_address_address
  on client_address (address)
	tablespace app_main_index;

create index ind_client_address_client_id
  on client_address (client_id)
	tablespace app_main_index;

-- only keep transactions, transaction inputs, or outputs for tracked addresses
create table blockchain_transaction (
  tx_id varchar2(1023),
	tx_hash varchar2(1023),
	block_hash varchar2(1023),
	status varchar2(1023), -- PENDING, CONFIRMED, ABANDONED
	transaction_version number(32,0),
	transaction_size number(32,0),
	transaction_vsize number(32,0),
	transaction_weight number(32,0),
	transaction_locktime number(32,0),
	confirmation_count number(32,0),
	create_date number(32,0),
	create_ts timestamp default systimestamp,
	CONSTRAINT pk_blockchain_transaction PRIMARY KEY (tx_id)
	  using index tablespace app_main_index
);

create index ind_blockchain_transaction_block_hash
  on blockchain_transaction (block_hash)
	tablespace app_main_index;

create table transaction_input (
  tx_id varchar2(1023),
	input_index number(32,0),
	utxo_id varchar2(1023),
	utxo_vout number(32,0),
	address varchar2(1023),
	value number(32,0),
	create_date number(32,0),
	create_ts timestamp default systimestamp
);

create index ind_transaction_input_tx_id
  on transaction_input (tx_id)
	tablespace app_main_index;

create index ind_transaction_input_address
  on transaction_input (address)
	tablespace app_main_index;

create table transaction_output (
  tx_id varchar2(1023),
	output_index number(32,0),
	address varchar2(1023),
	value number(32,0),
	script_hash varchar2(1023),
	is_spent number(1,0),
	spend_date number(32,0),
	create_date number(32,0),
	create_ts timestamp default systimestamp
);

create index ind_transaction_output_tx_id
  on transaction_output (tx_id)
	tablespace app_main_index;

create index ind_transaction_output_address
  on transaction_output (address)
	tablespace app_main_index;

create table address_update (
  update_id varchar2(1023),
  address varchar2(1023),
  currency_id varchar2(1023),
  tx_id varchar2(1023),
  type varchar2(1023), -- NEW, CONFIRMATION, CONFIRMED, ABANDONED
  data varchar2(32767), -- { statusFrom-To, blockFrom-To, inputs:[{address, value, utxo}], outputs:[{address, value, utxo,}] }
	create_date number(32,0),
	create_ts timestamp default systimestamp,
	CONSTRAINT pk_address_update PRIMARY KEY (update_id)
	  using index tablespace app_main_index
)
partition by range(create_ts)
interval (numtodsinterval(1,'day'))
(partition p0 values less than
  (to_date('2021-01-01','YYYY-MM-DD'))
);

create index ind_address_update_address
  on address_update (address)
	tablespace app_main_index;

create index ind_address_update_create_date
  on address_update (create_date)
	tablespace app_main_index;

GRANT SELECT, INSERT, UPDATE ON blockchain_block TO app_user_role;
GRANT SELECT, INSERT, UPDATE ON blockchain_address TO app_user_role;
GRANT SELECT, INSERT, UPDATE ON client_address TO app_user_role;
GRANT SELECT, INSERT, UPDATE ON blockchain_transaction TO app_user_role;
GRANT SELECT, INSERT, UPDATE ON transaction_input TO app_user_role;
GRANT SELECT, INSERT, UPDATE ON transaction_output TO app_user_role;
GRANT SELECT, INSERT ON address_update TO app_user_role;