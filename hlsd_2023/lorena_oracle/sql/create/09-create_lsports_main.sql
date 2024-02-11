# create ls_main schema in lorena
# fix services to write fixture/sport/league/player data to lorena
# deploy app to victoria
# grant read access to ls_main to fs_main

create user ls_main identified by ""
  default tablespace APP_MAIN
  quota unlimited on APP_MAIN
  quota unlimited on APP_MAIN_INDEX
  quota unlimited on APP_LOG;

grant connect, resource to ls_main;
alter session set current_schema = ls_main;

CREATE TABLE sport (
  id number(32,0),
  name varchar2(1023),

  create_date number(32,0),
  status varchar2(1023),
  version number(16,0),
  change_date number(32,0)
);
ALTER TABLE sport ADD CONSTRAINT pk_sport PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

CREATE TABLE location (
  id number(32,0),
  name varchar2(1023),

  create_date number(32,0),
  status varchar2(1023),
  version number(16,0),
  change_date number(32,0)
);
ALTER TABLE location ADD CONSTRAINT pk_location PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

CREATE TABLE bookmaker (
  id number(32,0),
  name varchar2(1023),

  create_date number(32,0),
  status varchar2(1023),
  version number(16,0),
  change_date number(32,0)
);
ALTER TABLE bookmaker ADD CONSTRAINT pk_bookmaker PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

CREATE TABLE market_type (
  id number(32,0),
  name varchar2(1023),

  create_date number(32,0),
  status varchar2(1023),
  version number(16,0),
  change_date number(32,0)
);
ALTER TABLE market_type ADD CONSTRAINT pk_market_type PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

CREATE TABLE league (
  id number(32,0),
	sport_id number(32,0),
  location_id number(32,0),
  name varchar2(1023),
	season varchar2(1023),

  create_date number(32,0),
  status varchar2(1023),
  version number(16,0),
  change_date number(32,0)
);
ALTER TABLE league ADD CONSTRAINT pk_league PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

CREATE TABLE player (
  id number(32,0),
	sport_id number(32,0),
  name varchar2(1023),

  create_date number(32,0),
  status varchar2(1023),
  version number(16,0),
  change_date number(32,0)
);
ALTER TABLE player ADD CONSTRAINT pk_player PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

CREATE TABLE fixture (
  id number(32,0),
	sport_id number(32,0),
  location_id number(32,0),
  league_id number(32,0),

  start_date number(32,0),
  fixture_status varchar2(1023),
  fixture_name varchar2(1023),
  event_type varchar2(1023),
  source_last_update_ts varchar2(1023),
  participants varchar2(32767),
  extra_data varchar2(32767),

  inplay_status varchar2(1023),
  inplay_order_status varchar2(1023),

  create_date number(32,0),
  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  partition_date date default SYSDATE
)
partition by range(partition_date)
interval (numtodsinterval(30,'day'))
(partition p0 values less than
  (to_date('2024-01-01','YYYY-MM-DD'))
)
ENABLE ROW MOVEMENT;

ALTER TABLE fixture ADD CONSTRAINT pk_fixture PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_fixture_start_date ON fixture (start_date) TABLESPACE app_main_index;

create role ls_data_writer;
create role ls_data_reader;

GRANT SELECT, INSERT, UPDATE ON sport TO ls_data_writer;
GRANT SELECT, INSERT, UPDATE ON location TO ls_data_writer;
GRANT SELECT, INSERT, UPDATE ON bookmaker TO ls_data_writer;
GRANT SELECT, INSERT, UPDATE ON market_type TO ls_data_writer;
GRANT SELECT, INSERT, UPDATE ON league TO ls_data_writer;
GRANT SELECT, INSERT, UPDATE ON player TO ls_data_writer;
GRANT SELECT, INSERT, UPDATE ON fixture TO ls_data_writer;

GRANT SELECT ON sport TO ls_data_reader;
GRANT SELECT ON location TO ls_data_reader;
GRANT SELECT ON bookmaker TO ls_data_reader;
GRANT SELECT ON market_type TO ls_data_reader;
GRANT SELECT ON league TO ls_data_reader;
GRANT SELECT ON player TO ls_data_reader;
GRANT SELECT ON fixture TO ls_data_reader;