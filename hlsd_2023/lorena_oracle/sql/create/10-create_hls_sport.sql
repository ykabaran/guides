create user hls_sport identified by ""
  default tablespace APP_MAIN
  quota unlimited on APP_MAIN
  quota unlimited on APP_MAIN_INDEX
  quota unlimited on APP_LOG;

grant connect, resource to hls_sport;
alter session set current_schema = hls_sport;

CREATE TABLE sport (
  id number(32,0),
  code varchar2(1023),
  name varchar2(1023),
  mapping_data varchar2(32767),
  extra_data varchar2(32767),

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE sport ADD CONSTRAINT pk_sport PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE UNIQUE INDEX unq_sport_code ON sport (code) TABLESPACE app_main_index;

CREATE TABLE location (
  id number(32,0),
  code varchar2(1023),
  name varchar2(1023),
  mapping_data varchar2(32767),
  extra_data varchar2(32767),

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE location ADD CONSTRAINT pk_location PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE UNIQUE INDEX unq_location_code ON location (code) TABLESPACE app_main_index;

CREATE TABLE bookmaker (
  id number(32,0),
  code varchar2(1023),
  name varchar2(1023),
  mapping_data varchar2(32767),
  extra_data varchar2(32767),

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE bookmaker ADD CONSTRAINT pk_bookmaker PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE UNIQUE INDEX unq_bookmaker_code ON bookmaker (code) TABLESPACE app_main_index;

CREATE TABLE market_type (
  id number(32,0),
  code varchar2(1023),
  name varchar2(1023),
  mapping_data varchar2(32767),
  extra_data varchar2(32767),

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE market_type ADD CONSTRAINT pk_market_type PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE UNIQUE INDEX unq_market_type_code ON market_type (code) TABLESPACE app_main_index;

CREATE TABLE play_event_type (
  id number(32,0),
  code varchar2(1023),
  name varchar2(1023),
  mapping_data varchar2(32767),
  extra_data varchar2(32767),

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE play_event_type ADD CONSTRAINT pk_play_event_type PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE UNIQUE INDEX unq_play_event_type_code ON play_event_type (code) TABLESPACE app_main_index;

CREATE TABLE result_type (
  id number(32,0),
  code varchar2(1023),
  name varchar2(1023),
  mapping_data varchar2(32767),
  extra_data varchar2(32767),

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE result_type ADD CONSTRAINT pk_result_type PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE UNIQUE INDEX unq_result_type_code ON result_type (code) TABLESPACE app_main_index;

CREATE TABLE league (
  id number(32,0),
	sport_id number(32,0),
  country_id number(32,0),
  name varchar2(1023),
	current_season varchar2(1023),
  standings varchar2(32767),
  statistics varchar2(32767),
  mapping_data varchar2(32767),
  extra_data varchar2(32767),

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE league ADD CONSTRAINT pk_league PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

CREATE TABLE venue (
  id number(32,0),
  sport_id number(32,0),
  country_id number(32,0),
  name varchar2(1023),
  mapping_data varchar2(32767),
  extra_data varchar2(32767),

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE venue ADD CONSTRAINT pk_venue PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

CREATE TABLE player (
  id number(32,0),
  sport_id number(32,0),
  country_id number(32,0),
  name varchar2(1023),
  venue_id number(32,0),
  members varchar2(32767),
  mapping_data varchar2(32767),
  extra_data varchar2(32767),

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE player ADD CONSTRAINT pk_player PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

CREATE TABLE person (
  id number(32,0),
  sport_id number(32,0),
  country_id number(32,0),
  person_type varchar2(1023),
  name varchar2(1023),
  mapping_data varchar2(32767),
  extra_data varchar2(32767),

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE person ADD CONSTRAINT pk_person PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

CREATE TABLE fixture (
  id number(32,0),
  sport_id number(32,0),
  country_id number(32,0),
  league_id number(32,0),
  name varchar2(1023),
  start_date number(32,0),
  fixture_type varchar2(1023),
  venue_id number(32,0),
  scoreboard varchar2(32767),
  point_by_point varchar2(32767),
  statistics varchar2(32767),
  head_to_head varchar2(32767),
  mapping_data varchar2(32767),
  extra_data varchar2(32767),

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
CREATE INDEX ind_fixture_start_date ON fixture (start_date) TABLESPACE app_main_index;

create table fixture_player (
  id number(32,0),
  fixture_id number(32,0),
  player_id number(32,0),
  position varchar2(1023),
  position_num number(16,0),
  statistics varchar2(32767),
  lineup varchar2(32767),
  extra_data varchar2(32767),

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
ALTER TABLE fixture_player ADD CONSTRAINT pk_fixture_player PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_fixture_player_fixture ON fixture_player (fixture_id) TABLESPACE app_main_index;

create table fixture_play_event (
  id number(32,0),
  fixture_id number(32,0),
  play_event_type_id number(32,0),
  event_data varchar2(32767),

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
ALTER TABLE fixture_play_event ADD CONSTRAINT pk_fixture_play_event PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_fixture_play_event_fixture ON fixture_play_event (fixture_id) TABLESPACE app_main_index;

create table fixture_result (
  id number(32,0),
  fixture_id number(32,0),
  result_type_id number(32,0),
  result_data varchar2(32767),

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
ALTER TABLE fixture_result ADD CONSTRAINT pk_fixture_result PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_fixture_result_fixture ON fixture_result (fixture_id) TABLESPACE app_main_index;

create table virtual_bookmaker_profile (
  id number(32,0),
  bookmaker_id number(32,0), -- some app_id in app_core.app_user table that has a virtual_bookmaker role
  name varchar2(1023), -- user made description
  data varchar2(32767),

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE virtual_bookmaker_profile ADD CONSTRAINT pk_virtual_bookmaker_profile PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

create table virtual_bookmaker_config (
  id number(32,0),
  bookmaker_id number(32,0),
  
  sport_id number(32,0),
  league_id number(32,0),
  market_type_id number(32,0),
  market_line varchar2(1023),
  bet_name varchar2(1023),
  fixture_id number(32,0),
  prematch_bet number(1,0),
  inplay_bet number(1,0),

  profile_id number(32,0),
  profile_data varchar2(32767),

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE virtual_bookmaker_config ADD CONSTRAINT pk_virtual_bookmaker_config PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;


create role hls_sport_writer;
create role hls_sport_reader;

GRANT SELECT, INSERT, UPDATE ON file_asset TO hls_sport_writer;
GRANT SELECT, INSERT, UPDATE ON sport TO hls_sport_writer;
GRANT SELECT, INSERT, UPDATE ON country TO hls_sport_writer;
GRANT SELECT, INSERT, UPDATE ON bookmaker TO hls_sport_writer;
GRANT SELECT, INSERT, UPDATE ON market_type TO hls_sport_writer;
GRANT SELECT, INSERT, UPDATE ON play_event_type TO hls_sport_writer;
GRANT SELECT, INSERT, UPDATE ON result_type TO hls_sport_writer;
GRANT SELECT, INSERT, UPDATE ON league TO hls_sport_writer;
GRANT SELECT, INSERT, UPDATE ON venue TO hls_sport_writer;
GRANT SELECT, INSERT, UPDATE ON player TO hls_sport_writer;
GRANT SELECT, INSERT, UPDATE ON person TO hls_sport_writer;
GRANT SELECT, INSERT, UPDATE ON fixture TO hls_sport_writer;
GRANT SELECT, INSERT, UPDATE ON fixture_player TO hls_sport_writer;
GRANT SELECT, INSERT, UPDATE ON fixture_prematch_bet TO hls_sport_writer;
GRANT SELECT, INSERT, UPDATE ON fixture_inplay_bet TO hls_sport_writer;
GRANT SELECT, INSERT, UPDATE ON fixture_play_event TO hls_sport_writer;
GRANT SELECT, INSERT, UPDATE ON fixture_result TO hls_sport_writer;
GRANT SELECT, INSERT, UPDATE ON fixture_prematch_bet_change TO hls_sport_writer;
GRANT SELECT, INSERT, UPDATE ON fixture_inplay_bet_change TO hls_sport_writer;
GRANT SELECT, INSERT, UPDATE ON sport_data_map TO hls_sport_writer;
GRANT SELECT, INSERT, UPDATE ON data_change_d1 TO hls_sport_writer;
GRANT SELECT, INSERT, UPDATE ON data_change_d7 TO hls_sport_writer;
GRANT SELECT, INSERT, UPDATE ON data_change_d30 TO hls_sport_writer;

GRANT SELECT ON file_asset TO hls_sport_reader;
GRANT SELECT ON sport TO hls_sport_reader;
GRANT SELECT ON country TO hls_sport_reader;
GRANT SELECT ON bookmaker TO hls_sport_reader;
GRANT SELECT ON market_type TO hls_sport_reader;
GRANT SELECT ON play_event_type TO hls_sport_reader;
GRANT SELECT ON result_type TO hls_sport_reader;
GRANT SELECT ON league TO hls_sport_reader;
GRANT SELECT ON venue TO hls_sport_reader;
GRANT SELECT ON player TO hls_sport_reader;
GRANT SELECT ON person TO hls_sport_reader;
GRANT SELECT ON fixture TO hls_sport_reader;
GRANT SELECT ON fixture_player TO hls_sport_reader;
GRANT SELECT ON fixture_prematch_bet TO hls_sport_reader;
GRANT SELECT ON fixture_inplay_bet TO hls_sport_reader;
GRANT SELECT ON fixture_play_event TO hls_sport_reader;
GRANT SELECT ON fixture_result TO hls_sport_reader;
GRANT SELECT ON fixture_prematch_bet_change TO hls_sport_reader;
GRANT SELECT ON fixture_inplay_bet_change TO hls_sport_reader;
GRANT SELECT ON sport_data_map TO hls_sport_reader;
GRANT SELECT ON data_change_d1 TO hls_sport_reader;
GRANT SELECT ON data_change_d7 TO hls_sport_reader;
GRANT SELECT ON data_change_d30 TO hls_sport_reader;

