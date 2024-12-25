create user ls_main identified by ""
  default tablespace APP_MAIN
  quota unlimited on APP_MAIN
  quota unlimited on APP_MAIN_INDEX;

grant connect, resource to ls_main;
alter session set current_schema = ls_main;


CREATE TABLE service_status (
  id number(32,0),
  name varchar2(1023) not null,
  data varchar2(32767),

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE service_status ADD CONSTRAINT pk_service_status PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE UNIQUE INDEX unq_service_status_name ON service_status (name) TABLESPACE app_main_index;

CREATE TABLE sport (
  id number(32,0),
  ls_id varchar2(1023) not null,
  name varchar2(1023) not null,

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE sport ADD CONSTRAINT pk_sport PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE UNIQUE INDEX unq_sport_ls_id ON sport (ls_id) TABLESPACE app_main_index;

CREATE TABLE location (
  id number(32,0),
  ls_id varchar2(1023) not null,
  name varchar2(1023) not null,

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE location ADD CONSTRAINT pk_location PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE UNIQUE INDEX unq_location_ls_id ON location (ls_id) TABLESPACE app_main_index;

CREATE TABLE bookmaker (
  id number(32,0),
  ls_id varchar2(1023) not null,
  name varchar2(1023) not null,

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE bookmaker ADD CONSTRAINT pk_bookmaker PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE UNIQUE INDEX unq_bookmaker_ls_id ON bookmaker (ls_id) TABLESPACE app_main_index;

CREATE TABLE market_type (
  id number(32,0),
  ls_id varchar2(1023) not null,
  name varchar2(1023) not null,

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE market_type ADD CONSTRAINT pk_market_type PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE UNIQUE INDEX unq_market_type_ls_id ON market_type (ls_id) TABLESPACE app_main_index;

CREATE TABLE league (
  id number(32,0),
  ls_id varchar2(1023) not null,
	sport_id number(32,0) not null,
  location_id number(32,0) not null,
  name varchar2(1023) not null,
	season varchar2(1023),

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE league ADD CONSTRAINT pk_league PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE UNIQUE INDEX unq_league_ls_id ON league (ls_id) TABLESPACE app_main_index;

CREATE TABLE player (
  id number(32,0) not null,
  ls_id varchar2(1023) not null,
	sport_id number(32,0) not null,
  name varchar2(1023) not null,

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE player ADD CONSTRAINT pk_player PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE UNIQUE INDEX unq_player_ls_id ON player (ls_id) TABLESPACE app_main_index;

CREATE TABLE fixture (
  id number(32,0),
  ls_id varchar2(1023) not null,
	sport_id number(32,0) not null,
  location_id number(32,0) not null,
  league_id number(32,0) not null,

  start_date number(32,0) not null,
  fixture_status varchar2(1023),
  fixture_name varchar2(1023),
  fixture_type varchar2(1023),

  inplay_status varchar2(1023),
  inplay_order_status varchar2(1023),
  livescore_status varchar2(1023),
  prematch_bets_status varchar2(1023),
  inplay_bets_status varchar2(1023),

  server_date number(32,0),
  source_last_update_ts varchar2(1023),

  participants varchar2(32767),

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0),
  partition_date date default sysdate not null 
)
partition by range(partition_date)
interval (numtodsinterval(30,'day'))
(partition p0 values less than
  (to_date('2024-01-01','YYYY-MM-DD'))
)
ENABLE ROW MOVEMENT;

ALTER TABLE fixture ADD CONSTRAINT pk_fixture PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE UNIQUE INDEX unq_fixture_ls_id ON fixture (ls_id) TABLESPACE app_main_index;
CREATE INDEX ind_fixture_start_date ON fixture (start_date) TABLESPACE app_main_index;
CREATE INDEX ind_fixture_change_date ON fixture (change_date) TABLESPACE app_main_index;

create table fixture_data_path (
  id number(32,0),
  name varchar2(1023) not null,

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE fixture_data_path ADD CONSTRAINT pk_fixture_data_path PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE UNIQUE INDEX unq_fixture_data_path_name ON fixture_data_path (name) TABLESPACE app_main_index;

CREATE TABLE fixture_data (
  id number(32,0),
  fixture_id number(32,0) not null,
  path_id number(32,0) not null,
  value varchar2(1023),

  server_date number(32,0),
  source_last_update_ts varchar2(1023),

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0),
  partition_date date default sysdate not null 
)
partition by range(partition_date)
interval (numtodsinterval(7,'day'))
(partition p0 values less than
  (to_date('2024-01-01','YYYY-MM-DD'))
)
ENABLE ROW MOVEMENT;

ALTER TABLE fixture_data ADD CONSTRAINT pk_fixture_data PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_fixture_data_fixture ON fixture_data (fixture_id) TABLESPACE app_main_index;
CREATE INDEX ind_fixture_data_change_date ON fixture_data (change_date) TABLESPACE app_main_index;

CREATE TABLE fixture_prematch_bet (
  id number(32,0),
  ls_id varchar2(1023) not null,
  fixture_id number(32,0) not null,
  bookmaker_id number(32,0) not null,
  market_type_id number(32,0) not null,

  market_baseline varchar2(1023),
  market_line varchar2(1023),
  bet_name varchar2(1023) not null,
  bet_status varchar2(1023),
  bet_settlement varchar2(1023),
  start_price number(16,4),
  current_price number(16,4),
  last_price number(16,4),

  server_date number(32,0),
  source_last_update_ts varchar2(1023),

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0),
  partition_date date default sysdate not null 
)
partition by range(partition_date)
interval (numtodsinterval(7,'day'))
(partition p0 values less than
  (to_date('2024-01-01','YYYY-MM-DD'))
)
ENABLE ROW MOVEMENT;

ALTER TABLE fixture_prematch_bet ADD CONSTRAINT pk_fixture_prematch_bet PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_fixture_prematch_bet_fixture ON fixture_prematch_bet (fixture_id) TABLESPACE app_main_index;
CREATE INDEX ind_fixture_prematch_bet_change_date ON fixture_prematch_bet (change_date) TABLESPACE app_main_index;

CREATE TABLE fixture_inplay_bet (
  id number(32,0),
  ls_id varchar2(1023) not null,
  fixture_id number(32,0) not null,
  bookmaker_id number(32,0) not null,
  market_type_id number(32,0) not null,
  
  market_baseline varchar2(1023),
  market_line varchar2(1023),
  bet_name varchar2(1023) not null,
  bet_status varchar2(1023),
  bet_settlement varchar2(1023),
  start_price number(16,4),
  current_price number(16,4),
  last_price number(16,4),

  server_date number(32,0),
  source_last_update_ts varchar2(1023),

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0),
  partition_date date default sysdate not null 
)
partition by range(partition_date)
interval (numtodsinterval(1,'day'))
(partition p0 values less than
  (to_date('2024-01-01','YYYY-MM-DD'))
)
ENABLE ROW MOVEMENT;

ALTER TABLE fixture_inplay_bet ADD CONSTRAINT pk_fixture_inplay_bet PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_fixture_inplay_bet_fixture ON fixture_inplay_bet (fixture_id) TABLESPACE app_main_index;
CREATE INDEX ind_fixture_inplay_bet_change_date ON fixture_inplay_bet (change_date) TABLESPACE app_main_index;


create role ls_data_writer;
create role ls_data_reader;

GRANT SELECT, INSERT, UPDATE ON service_status TO ls_data_writer;
GRANT SELECT, INSERT, UPDATE ON sport TO ls_data_writer;
GRANT SELECT, INSERT, UPDATE ON location TO ls_data_writer;
GRANT SELECT, INSERT, UPDATE ON bookmaker TO ls_data_writer;
GRANT SELECT, INSERT, UPDATE ON market_type TO ls_data_writer;
GRANT SELECT, INSERT, UPDATE ON league TO ls_data_writer;
GRANT SELECT, INSERT, UPDATE ON player TO ls_data_writer;
GRANT SELECT, INSERT, UPDATE ON fixture TO ls_data_writer;
GRANT SELECT, INSERT, UPDATE ON fixture_data_path TO ls_data_writer;
GRANT SELECT, INSERT, UPDATE ON fixture_data TO ls_data_writer;
GRANT SELECT, INSERT, UPDATE ON fixture_prematch_bet TO ls_data_writer;
GRANT SELECT, INSERT, UPDATE ON fixture_inplay_bet TO ls_data_writer;

GRANT SELECT ON service_status TO ls_data_reader;
GRANT SELECT ON sport TO ls_data_reader;
GRANT SELECT ON location TO ls_data_reader;
GRANT SELECT ON bookmaker TO ls_data_reader;
GRANT SELECT ON market_type TO ls_data_reader;
GRANT SELECT ON league TO ls_data_reader;
GRANT SELECT ON player TO ls_data_reader;
GRANT SELECT ON fixture TO ls_data_reader;
GRANT SELECT ON fixture_data_path TO ls_data_reader;
GRANT SELECT ON fixture_data TO ls_data_reader;
GRANT SELECT ON fixture_prematch_bet TO ls_data_reader;
GRANT SELECT ON fixture_inplay_bet TO ls_data_reader;
