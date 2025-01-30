create user account_main identified by ""
  default tablespace APP_MAIN
  quota unlimited on APP_MAIN
  quota unlimited on APP_MAIN_INDEX;

grant connect, resource to account_main;
alter session set current_schema = account_main;

CREATE TABLE currency (
  id number(32,0),
  code varchar2(1023) not null,
  name varchar2(1023) not null,
  precision number(16,0) not null default 2,
  normalized_value number(32,0) not null default 0, -- unit value in USD for example

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE currency ADD CONSTRAINT pk_currency PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE UNIQUE INDEX unq_currency_code ON currency (code) TABLESPACE app_main_index;

create table account (
  id number(32,0),
  owner_id number(32,0),
  owner_type varchar2(1023), -- user, app, session
  type varchar2(1023), -- payment_account/commission_account
  name varchar2(1023), -- any name given to the account
  currency_id number(32,0),
  balance number(32,0), -- stored as integer, decimal precision is determined by the given currency
  pending_in number(32,0),
  pending_out number(32,0),
  total_in number(32,0),
  total_out number(32,0),

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0),
  partition_date date default sysdate not null 
)
partition by range(partition_date)
interval (numtodsinterval(7,'day'))
(partition p0 values less than
  (to_date('2025-01-01','YYYY-MM-DD'))
)
ENABLE ROW MOVEMENT;
ALTER TABLE account ADD CONSTRAINT pk_account PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_account_owner ON account (owner_id) TABLESPACE app_main_index;

create table wallet (
  id number(32,0),
  owner_id number(32,0),
  owner_type varchar2(1023), -- user, app, session
  name varchar2(1023), -- any name given to the wallet
  data varchar2(32767), -- how to spend/return the funds, bonus first etc

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0),
  partition_date date default sysdate not null 
)
partition by range(partition_date)
interval (numtodsinterval(30,'day'))
(partition p0 values less than
  (to_date('2025-01-01','YYYY-MM-DD'))
)
ENABLE ROW MOVEMENT;
ALTER TABLE wallet ADD CONSTRAINT pk_wallet PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_wallet_owner ON wallet (owner_id) TABLESPACE app_main_index;

create table wallet_content (
  id number(32,0),
  wallet_id number(32,0),
  content_id number(32,0),
  content_type varchar2(1023), -- account/wallet

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0),
  partition_date date default sysdate not null 
)
partition by range(partition_date)
interval (numtodsinterval(30,'day'))
(partition p0 values less than
  (to_date('2025-01-01','YYYY-MM-DD'))
)
ENABLE ROW MOVEMENT;
ALTER TABLE wallet_content ADD CONSTRAINT pk_wallet_content PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE UNIQUE INDEX unq_wallet_content ON wallet_content (wallet_id, content_id) TABLESPACE app_main_index;

create table contract (
  id number(32,0),
  owner_id number(32,0), -- the app_id of the game_house/virtual_bookmaker
  type varchar2(1023), -- bet.instant_game.game_code, deposit.bank_transfer, deposit.cash, withdraw.cash, bet.sports
  data varchar2(32767), -- json data for the bet_id and such

  start_date number(32,0),
  end_date number(32,0),

  status varchar2(1023), -- open, finalized, cancelled
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0),
  partition_date date default sysdate not null 
)
partition by range(partition_date)
interval (numtodsinterval(30,'day'))
(partition p0 values less than
  (to_date('2025-01-01','YYYY-MM-DD'))
);
ALTER TABLE contract ADD CONSTRAINT pk_contract PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_contract_owner_date ON contract (owner_id, create_date) TABLESPACE app_main_index;
CREATE INDEX ind_contract_change_date ON contract (change_date) TABLESPACE app_main_index;

create table contract_step (
  id number(32,0),
  ref_id varchar2(1023), -- reference transaction_id if the payment was processed remotely
  contract_id number(32,0),
  type number(32,0), -- place_bet, increse_bet, bet_lost, bet_won, win_cancelled, bet_cancelled
  data varchar2(32767), -- json data about the contract step, maybe more game ids, foreign transaction ids, etc

  status varchar2(1023), -- the contract status
  version number(16,0), -- the contract version
  create_date number(32,0),
  partition_date date default sysdate not null 
)
partition by range(partition_date)
interval (numtodsinterval(30,'day'))
(partition p0 values less than
  (to_date('2025-01-01','YYYY-MM-DD'))
)
pctfree 0;
ALTER TABLE contract_step ADD CONSTRAINT pk_contract_step PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_contract_step_contract ON contract_step (contract_id) TABLESPACE app_main_index;
CREATE UNIQUE INDEX ind_contract_step_ref_id ON contract_step (ref_id) TABLESPACE app_main_index;

create table transaction (
  id number(32,0),
  account_id number(32,0),
  contract_id number(32,0),
  contract_step_id number(32,0),
  type varchar2(1023), -- payment, winning
  direction varchar2(1023), -- none.to.pending_in, pending_in.to.balance, balance.to.pending_out, pending_out.to.none, none.to.balance, balance.to.none
  amount number(32,0), -- always a positive number, negative is determined by direction
  balance_before number(32,0),
  balance_after number(32,0), -- set only if the transaction changed the balance

  create_date number(32,0),
  partition_date date default sysdate not null 
)
partition by range(partition_date)
interval (numtodsinterval(30,'day'))
(partition p0 values less than
  (to_date('2025-01-01','YYYY-MM-DD'))
)
pctfree 0;
ALTER TABLE transaction ADD CONSTRAINT pk_transaction PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_transaction_account ON transaction (account_id, create_date) TABLESPACE app_main_index;
CREATE INDEX ind_transaction_contract ON transaction (contract_id) TABLESPACE app_main_index;

create table account_snapshot (
  id number(32,0),
  account_id number(32,0),

  balance number(32,0),
  pending_in number(32,0),
  pending_out numbeR(32,0),
  total_in number(32,0),
  total_out number(32,0),

  create_date number(32,0),
  partition_date date default sysdate not null 
)
partition by range(partition_date)
interval (numtodsinterval(30,'day'))
(partition p0 values less than
  (to_date('2025-01-01','YYYY-MM-DD'))
)
pctfree 0;
ALTER TABLE account_snapshot ADD CONSTRAINT pk_account_snapshot PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_account_snapshot_account_date ON account_snapshot (account_id, create_date) TABLESPACE app_main_index;

create table contract_rollup (
  id number(32,0),
  owner_id number(32,0),
  contract_type varchar2(1023),
  account_id number(32,0),

  transaction_count number(16,0),
  total_in number(32,0),
  total_out number(32,0),

  start_date number(32,0),
  end_date number(32,0),
  partition_date date default sysdate not null 
)
partition by range(partition_date)
interval (numtodsinterval(30,'day'))
(partition p0 values less than
  (to_date('2025-01-01','YYYY-MM-DD'))
)
pctfree 0;
ALTER TABLE contract_rollup ADD CONSTRAINT pk_contract_rollup PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_contract_rollup_owner_date ON contract_rollup (owner_id, start_date) TABLESPACE app_main_index;
CREATE INDEX ind_contract_rollup_account_date ON contract_rollup (account_id, start_date) TABLESPACE app_main_index;

create role app_account_reader;
create role app_account_writer;
create role app_account_deleter;

grant select on currency to app_account_reader;
grant select on account to app_account_reader;
grant select on wallet to app_account_reader;
grant select on wallet_content to app_account_reader;
grant select on contract to app_account_reader;
grant select on contract_step to app_account_reader;
grant select on transaction to app_account_reader;
grant select on account_snapshot to app_account_reader;
grant select on contract_rollup to app_account_reader;

grant select,insert,update on currency to app_account_writer;
grant select,insert,update on account to app_account_writer;
grant select,insert,update on wallet to app_account_writer;
grant select,insert,update on wallet_content to app_account_writer;
grant select,insert,update on contract to app_account_writer;
grant select,insert,update on contract_step to app_account_writer;
grant select,insert,update on transaction to app_account_writer;
grant select,insert,update on account_snapshot to app_account_writer;
grant select,insert,update on contract_rollup to app_account_writer;

grant select,insert,update,delete on currency to app_account_deleter;
grant select,insert,update,delete on account to app_account_deleter;
grant select,insert,update,delete on wallet to app_account_deleter;
grant select,insert,update,delete on wallet_content to app_account_deleter;
grant select,insert,update,delete on contract to app_account_deleter;
grant select,insert,update,delete on contract_step to app_account_deleter;
grant select,insert,update,delete on transaction to app_account_deleter;
grant select,insert,update,delete on account_snapshot to app_account_deleter;
grant select,insert,update,delete on contract_rollup to app_account_deleter;