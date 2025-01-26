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

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE currency ADD CONSTRAINT pk_currency PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE UNIQUE INDEX unq_currency_code ON currency (code) TABLESPACE app_main_index;

create table account (
  id number(32,0),
  type varchar2(1023), -- payment_account/commission_account
  currency_id number(32,0),
  balance number(32,0), -- stored as integer, decimal precision is determined by the given currency
  pending_in number(32,0),
  pending_out numbeR(32,0),
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

create table wallet (
  id number(32,0),
  owner_id number(32,0),

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

create table wallet_content (
  id number(32,0),
  wallet_id number(32,0),
  type varchar2(1023), -- account/wallet
  content_id number(32,0),

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
CREATE UNIQUE INDEX unq_wallet_content ON currency (wallet_id, content_id) TABLESPACE app_main_index;

create table contract (
  id number(32,0),
  type varchar2(1023), -- played_sports_bet, played_game
  data varchar2(32767), -- json data for the bet_id and such

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
ALTER TABLE contract ADD CONSTRAINT pk_contract PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

create table contract_step (
  id number(32,0),
  contract_id number(32,0),
  step_num number(16,0),
  type number(32,0), -- place_bet, increse_bet, bet_lost, bet_won
  data varchar2(32767), -- json data about the contract step, maybe more game ids, foreign transaction ids, etc

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
ALTER TABLE contract_step ADD CONSTRAINT pk_contract_step PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_contract_step_contract ON transaction (contract_id) TABLESPACE app_main_index;

create table transaction (
  id number(32,0),
  account_id number(32,0),
  contract_id number(32,0),
  contract_step_id number(32,0),
  type varchar2(1023), -- none.to.pending_in, pending_in.to.balance, balance.to.pending_out, pending_out.to.none, none.to.balance, balance.to.none
  amount number(32,0) -- always a positive number, negative is determined by type

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
ALTER TABLE transaction ADD CONSTRAINT pk_transaction PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_transaction_account ON transaction (account_id) TABLESPACE app_main_index;
CREATE INDEX ind_transaction_contract ON transaction (contract_id) TABLESPACE app_main_index;