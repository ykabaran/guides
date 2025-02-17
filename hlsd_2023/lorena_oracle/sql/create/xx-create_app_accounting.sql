create user app_accounting identified by ""
  default tablespace APP_MAIN
  quota unlimited on APP_MAIN
  quota unlimited on APP_MAIN_INDEX;

grant connect, resource to app_accounting;
alter session set current_schema = app_accounting;

CREATE TABLE app_currency (
  id number(32,0),
  code varchar2(1023) not null,
  name varchar2(1023) not null,
  precision number(16,0) default 2 not null,
  data varchar2(32767),

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE app_currency ADD CONSTRAINT pk_app_currency PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE UNIQUE INDEX unq_app_currency_code ON app_currency (code) TABLESPACE app_main_index;

create table app_account (
  id number(32,0),
  owner_id number(32,0) not null,
  owner_type varchar2(1023) not null, -- user, app, session
  type varchar2(1023) not null, -- payment_account/commission_account
  name varchar2(1023) not null, -- any name given to the account
  currency_id number(32,0) not null,
  balance number(32,0) not null, -- stored as integer, decimal precision is determined by the given currency
  pending_in number(32,0) not null,
  pending_out number(32,0) not null,
  total_in number(32,0) not null,
  total_out number(32,0) not null,

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
ALTER TABLE app_account ADD CONSTRAINT pk_app_account PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_app_account_owner ON app_account (owner_id) TABLESPACE app_main_index;

create table app_wallet (
  id number(32,0),
  owner_id number(32,0) not null,
  owner_type varchar2(1023) not null, -- user, app, session
  name varchar2(1023) not null, -- any name given to the wallet
  data varchar2(32767) not null, -- how to spend/return the funds, bonus first etc

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
ALTER TABLE app_wallet ADD CONSTRAINT pk_app_wallet PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_app_wallet_owner ON app_wallet (owner_id) TABLESPACE app_main_index;

create table app_wallet_content (
  id number(32,0),
  wallet_id number(32,0) not null,
  content_id number(32,0) not null,
  content_type varchar2(1023) not null, -- account/wallet

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
ALTER TABLE app_wallet_content ADD CONSTRAINT pk_app_wallet_content PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE UNIQUE INDEX unq_app_wallet_content ON app_wallet_content (wallet_id, content_id) TABLESPACE app_main_index;

create table app_contract (
  id number(32,0),
  owner_id number(32,0) not null, -- the app_id of the game_house/virtual_bookmaker
  type varchar2(1023) not null, -- bet.instant_game.game_code, deposit.bank_transfer, deposit.cash, withdraw.cash, bet.sports
  data varchar2(32767) not null, -- json data for the bet_id and such

  start_date number(32,0) not null,
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
ALTER TABLE app_contract ADD CONSTRAINT pk_app_contract PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_app_contract_owner_date ON app_contract (owner_id, create_date) TABLESPACE app_main_index;
CREATE INDEX ind_app_contract_change_date ON app_contract (change_date) TABLESPACE app_main_index;

create table app_contract_step (
  id number(32,0),
  ref_id varchar2(1023), -- reference transaction_id if the payment was processed remotely
  contract_id number(32,0) not null,
  type number(32,0) not null, -- place_bet, increse_bet, bet_lost, bet_won, win_cancelled, bet_cancelled
  data varchar2(32767), -- json data about the contract step, maybe more game ids, foreign transaction ids, etc

  status varchar2(1023) not null, -- the contract status
  version number(16,0) not null, -- the contract version
  create_date number(32,0),
  partition_date date default sysdate not null 
)
partition by range(partition_date)
interval (numtodsinterval(30,'day'))
(partition p0 values less than
  (to_date('2025-01-01','YYYY-MM-DD'))
)
pctfree 0;
ALTER TABLE app_contract_step ADD CONSTRAINT pk_app_contract_step PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_app_contract_step_contract ON app_contract_step (contract_id) TABLESPACE app_main_index;
CREATE UNIQUE INDEX ind_app_contract_step_ref_id ON app_contract_step (ref_id) TABLESPACE app_main_index;

create table app_transaction (
  id number(32,0),
  account_id number(32,0) not null,
  contract_id number(32,0) not null,
  contract_step_id number(32,0) not null,
  type varchar2(1023) not null, -- payment, winning
  source varchar2(1023) not null, -- none, pending_in, balance, pending_out
  target varchar2(1023) not null, -- pending_in, balance, pending_out, none
  amount number(32,0) not null, -- always a positive number, negative is determined by source and target
  balance_before number(32,0) not null,
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
ALTER TABLE app_transaction ADD CONSTRAINT pk_app_transaction PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_app_transaction_account ON app_transaction (account_id, create_date) TABLESPACE app_main_index;
CREATE INDEX ind_app_transaction_contract ON app_transaction (contract_id) TABLESPACE app_main_index;

create table account_rollup (
  id number(32,0),
  account_id number(32,0) not null,
  contract_type varchar2(1023) not null,

  transaction_count number(16,0) not null,
  total_in number(32,0) not null,
  total_out number(32,0) not null,
  start_date number(32,0) not null,
  end_date number(32,0) not null,

  create_date number(32,0),
  partition_date date default sysdate not null 
)
partition by range(partition_date)
interval (numtodsinterval(30,'day'))
(partition p0 values less than
  (to_date('2025-01-01','YYYY-MM-DD'))
)
pctfree 0;
ALTER TABLE account_rollup ADD CONSTRAINT pk_account_rollup PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_account_rollup_account_date ON account_rollup (account_id, start_date) TABLESPACE app_main_index;

create table contract_rollup (
  id number(32,0),
  owner_id number(32,0) not null,
  contract_type varchar2(1023) not null,

  transaction_count number(16,0) not null,
  total_in number(32,0) not null,
  total_out number(32,0) not null,
  start_date number(32,0) not null,
  end_date number(32,0) not null,

  create_date number(32,0),
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

create role app_accounting_reader;
create role app_accounting_writer;
create role app_accounting_deleter;

grant select on app_currency to app_accounting_reader;
grant select on app_account to app_accounting_reader;
grant select on app_wallet to app_accounting_reader;
grant select on app_wallet_content to app_accounting_reader;
grant select on app_contract to app_accounting_reader;
grant select on app_contract_step to app_accounting_reader;
grant select on app_transaction to app_accounting_reader;
grant select on account_rollup to app_accounting_reader;
grant select on contract_rollup to app_accounting_reader;

grant select,insert,update on app_currency to app_accounting_writer;
grant select,insert,update on app_account to app_accounting_writer;
grant select,insert,update on app_wallet to app_accounting_writer;
grant select,insert,update on app_wallet_content to app_accounting_writer;
grant select,insert,update on app_contract to app_accounting_writer;
grant select,insert,update on app_contract_step to app_accounting_writer;
grant select,insert,update on app_transaction to app_accounting_writer;
grant select,insert,update on account_rollup to app_accounting_writer;
grant select,insert,update on contract_rollup to app_accounting_writer;

grant select,insert,update,delete on app_currency to app_accounting_deleter;
grant select,insert,update,delete on app_account to app_accounting_deleter;
grant select,insert,update,delete on app_wallet to app_accounting_deleter;
grant select,insert,update,delete on app_wallet_content to app_accounting_deleter;
grant select,insert,update,delete on app_contract to app_accounting_deleter;
grant select,insert,update,delete on app_contract_step to app_accounting_deleter;
grant select,insert,update,delete on app_transaction to app_accounting_deleter;
grant select,insert,update,delete on account_rollup to app_accounting_deleter;
grant select,insert,update,delete on contract_rollup to app_accounting_deleter;