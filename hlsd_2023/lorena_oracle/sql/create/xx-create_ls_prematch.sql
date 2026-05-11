create user ls_prematch identified by ""
  default tablespace APP_MAIN
  quota unlimited on APP_MAIN
  quota unlimited on APP_MAIN_INDEX;

grant connect, resource to ls_prematch;
alter session set current_schema = ls_prematch;


CREATE TABLE fixture (
  id number(32,0),
  ls_id varchar2(1023) not null,
  fixture_type number(16,0) not null,
	sport_id number(32,0),
  location_id number(32,0),
  league_id number(32,0),

  start_date number(32,0),
  server_date number(32,0),
  last_update_ts varchar2(1023),

  fixture_status number(16,0),
  fixture_name varchar2(1023),

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0),
  partition_date date default sysdate not null 
)
partition by range(partition_date)
interval (numtodsinterval(30,'day'))
(partition p0 values less than
  (to_date('2026-01-01','YYYY-MM-DD'))
)
ENABLE ROW MOVEMENT;

ALTER TABLE fixture ADD CONSTRAINT pk_fixture PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE UNIQUE INDEX unq_fixture_ls_id ON fixture (ls_id) TABLESPACE app_main_index;
CREATE INDEX ind_fixture_start_date ON fixture (start_date) TABLESPACE app_main_index;
CREATE INDEX ind_fixture_change_date ON fixture (change_date) TABLESPACE app_main_index;

CREATE TABLE fixture_data (
  id number(32,0),
  fixture_id number(32,0) not null,
  path_id number(32,0) not null,
  value varchar2(1023),

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0),
  partition_date date default sysdate not null 
)
partition by range(partition_date)
interval (numtodsinterval(7,'day'))
(partition p0 values less than
  (to_date('2026-01-01','YYYY-MM-DD'))
)
ENABLE ROW MOVEMENT;

ALTER TABLE fixture_data ADD CONSTRAINT pk_fixture_data PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_fixture_data_fixture ON fixture_data (fixture_id) TABLESPACE app_main_index;
CREATE INDEX ind_fixture_data_change_date ON fixture_data (change_date) TABLESPACE app_main_index;

CREATE TABLE fixture_bet (
  id number(32,0),
  ls_id varchar2(1023) not null,
  fixture_id number(32,0) not null,
  market_type_id number(32,0) not null,

  provider_bet_id varchar2(1023),
  market_baseline varchar2(1023),
  market_line varchar2(1023),
  bet_name varchar2(1023),
  bet_order number(16,0),
  bet_status number(16,0),
  bet_settlement number(16,0),
  bet_suspension_reason number(16,0),

  probability number(12,8),
  start_price number(16,4),
  current_price number(16,4),
  last_price number(16,4),

  server_date number(32,0),
  last_update_ts varchar2(1023),

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0),
  partition_date date default sysdate not null 
)
partition by range(partition_date)
interval (numtodsinterval(7,'day'))
(partition p0 values less than
  (to_date('2026-01-01','YYYY-MM-DD'))
)
ENABLE ROW MOVEMENT;

ALTER TABLE fixture_bet ADD CONSTRAINT pk_fixture_bet PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_fixture_bet_fixture ON fixture_bet (fixture_id) TABLESPACE app_main_index;
CREATE INDEX ind_fixture_bet_change_date ON fixture_bet (change_date) TABLESPACE app_main_index;


create role ls_prematch_writer;
create role ls_prematch_reader;

GRANT SELECT, INSERT, UPDATE ON fixture TO ls_prematch_writer;
GRANT SELECT, INSERT, UPDATE ON fixture_data TO ls_prematch_writer;
GRANT SELECT, INSERT, UPDATE ON fixture_bet TO ls_prematch_writer;

GRANT SELECT ON fixture TO ls_prematch_reader;
GRANT SELECT ON fixture_data TO ls_prematch_reader;
GRANT SELECT ON fixture_bet TO ls_prematch_reader;
