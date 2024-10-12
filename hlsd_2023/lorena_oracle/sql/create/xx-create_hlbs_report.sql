create user hlbs_report identified by ""
  default tablespace APP_MAIN
  quota unlimited on APP_MAIN
  quota unlimited on APP_MAIN_INDEX
  quota unlimited on APP_LOG;

grant connect, resource to hlbs_report;

alter session set current_schema = hlbs_report;

create table betcardmas_stat (
  id number(32,0), -- generated from card_date, teg_id, cgt_id, bcde_rateno
  card_date date, -- rounded to 10min for prematch, 1min for inplay, unique index
  teg_id number(32,0), -- unique index
  cgt_id number(32,0), -- unique index
  bcde_rateno number(32,0), -- unique index
  cgtg_id number(32,0), -- not included in unique index because cgt_id is
  teg_type varchar2(1023), -- prematch or inplay

  total_bets number(32,0),
  total_stake number(24,2),
  total_return number(24,2),

  total_open_bets number(32,0),
  total_open_stake number(24,2),
  total_open_return number(24,2),

  total_potentially_won_bets number(32,0),
  total_potentially_won_stake number(24,2),
  total_potentially_won_return number(24,2),

  total_lost_bets number(32,0),
  total_lost_stake number(24,2),
  total_lost_return number(24,2),

  total_open_but_lost_bets number(32,0),
  total_open_but_lost_stake number(24,2),
  total_open_but_lost_return number(24,2),

  total_won_but_lost_bets number(32,0),
  total_won_but_lost_stake number(24,2),
  total_won_but_lost_return number(24,2),

  total_won_bets number(32,0),
  total_won_stake number(24,2),
  total_won_return number(24,2),

  total_sold_bets number(32,0),
  total_sold_stake number(24,2),
  total_sold_return number(24,2),

  create_date number(32,0),
  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),

  partition_date date not null
)
partition by range(partition_date)
interval (numtodsinterval(30,'day'))
(partition p0 values less than
  (to_date('2024-01-01','YYYY-MM-DD'))
)
tablespace APP_MAIN;
ALTER TABLE betcardmas_stat ADD CONSTRAINT pk_betcardmas_stat PRIMARY KEY (id) USING INDEX TABLESPACE APP_MAIN_INDEX;
CREATE UNIQUE INDEX unq_betcardmas_stat ON betcardmas_stat (card_date, teg_id, cgt_id, bcde_rateno) tablespace APP_MAIN_INDEX;

create table customer_stat (
  id number(32,0), -- generated from bet_date, bet_type, sub_id 
  bet_date date, -- rounded to 10min, unique index
  bet_type varchar2(1023) -- unique index, betting-roulette-blackjack-holdem-etc
  sub_id number(32,0), -- unique index
  sub_type varchar2(1023), -- tc, kktc, nicocard

  total_bets number(32,0),
  total_stake number(24,2),
  total_return number(24,2),

  total_lost_bets number(32,0),
  total_lost_stake number(24,2),
  total_lost_return number(24,2),

  total_won_bets number(32,0),
  total_won_stake number(24,2),
  total_won_return number(24,2),

  create_date number(32,0),
  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),

  partition_date date not null
)
partition by range(partition_date)
interval (numtodsinterval(30,'day'))
(partition p0 values less than
  (to_date('2024-01-01','YYYY-MM-DD'))
)
tablespace APP_MAIN;
ALTER TABLE customer_stat ADD CONSTRAINT pk_customer_stat PRIMARY KEY (id) USING INDEX TABLESPACE APP_MAIN_INDEX;
CREATE UNIQUE INDEX unq_customer_stat ON customer_stat (bet_date, bet_type, sub_id) tablespace APP_MAIN_INDEX;

create table customer_stat (
  id number(32,0), -- generated from bet_date, bet_type, sub_id 
  bet_date date, -- rounded to 10min, unique index
  bet_type varchar2(1023) -- unique index, betting-roulette-blackjack-holdem-etc
  sub_id number(32,0), -- unique index
  sub_type varchar2(1023), -- tc, kktc, nicocard

  total_bets number(32,0),
  total_stake number(24,2),
  total_return number(24,2),

  total_lost_bets number(32,0),
  total_lost_stake number(24,2),
  total_lost_return number(24,2),

  total_won_bets number(32,0),
  total_won_stake number(24,2),
  total_won_return number(24,2),

  create_date number(32,0),
  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),

  partition_date date not null
)
partition by range(partition_date)
interval (numtodsinterval(30,'day'))
(partition p0 values less than
  (to_date('2024-01-01','YYYY-MM-DD'))
)
tablespace APP_MAIN;
ALTER TABLE customer_stat ADD CONSTRAINT pk_customer_stat PRIMARY KEY (id) USING INDEX TABLESPACE APP_MAIN_INDEX;
CREATE UNIQUE INDEX unq_customer_stat ON customer_stat (bet_date, bet_type, sub_id) tablespace APP_MAIN_INDEX;

create table data_change_d1 (
  id number(32,0),
  table_id number(32,0),
  data_id number(32,0),

  change_type varchar2(1023),
  before_data varchar2(32767),
  after_data varchar2(32767),
  source_data varchar2(32767),

  version number(16,0),
  change_date number(32,0),
  partition_date date default sysdate
)
partition by range(partition_date)
interval (numtodsinterval(1,'day'))
(partition p0 values less than
  (to_date('2024-01-01','YYYY-MM-DD'))
)
nologging
tablespace app_log;
ALTER TABLE data_change_d7 ADD CONSTRAINT pk_data_change_d7 PRIMARY KEY (id) USING INDEX TABLESPACE app_log;
CREATE INDEX ind_data_change_d7_change_date ON data_change_d7 (change_date) tablespace app_log;
CREATE INDEX ind_data_change_d7_data_id ON data_change_d7 (data_id) tablespace app_log;

create role hlbs_report_reader;
create role hlbs_report_writer;

grant select on betcardmas_stat to hlbs_report_reader;
grant select on data_change_d1 to hlbs_report_reader;

grant select, insert, update on betcardmas_stat to hlbs_report_writer;
grant select, insert, update on data_change_d1 to hlbs_report_writer;



