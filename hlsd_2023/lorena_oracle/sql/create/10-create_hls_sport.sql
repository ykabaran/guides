create user hls_sport identified by ""
  default tablespace APP_MAIN
  quota unlimited on APP_MAIN
  quota unlimited on APP_MAIN_INDEX
  quota unlimited on APP_LOG;

grant connect, resource to hls_sport;
alter session set current_schema = hls_sport;

CREATE TABLE file_asset (
  id number(32,0),
  category varchar2(1023),
  name varchar2(1023),
  file_name varchar2(1023),
  file_size number(32,0),
  file_mime_type varchar2(1023),
  file_hash varchar2(1023),
  source_url varchar2(1023),
  file_servers varchar2(1023),
  extra_data varchar2(32767),

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
ALTER TABLE file_asset ADD CONSTRAINT pk_file_asset PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

CREATE TABLE sport (
  id number(32,0),
  code varchar2(1023),
  name varchar2(1023),
  icon_file_id number(32,0),
  extra_data varchar2(32767),

  create_date number(32,0),
  status varchar2(1023),
  version number(16,0),
  change_date number(32,0)
);
ALTER TABLE sport ADD CONSTRAINT pk_sport PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

CREATE TABLE country (
  id number(32,0),
  code varchar2(1023),
  name varchar2(1023),
  flag_file_id number(32,0),
  extra_data varchar2(32767),

  create_date number(32,0),
  status varchar2(1023),
  version number(16,0),
  change_date number(32,0)
);
ALTER TABLE country ADD CONSTRAINT pk_country PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

CREATE TABLE bookmaker (
  id number(32,0),
  code varchar2(1023),
  name varchar2(1023),
  extra_data varchar2(32767),

  create_date number(32,0),
  status varchar2(1023),
  version number(16,0),
  change_date number(32,0)
);
ALTER TABLE bookmaker ADD CONSTRAINT pk_bookmaker PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

CREATE TABLE market_type (
  id number(32,0),
  code varchar2(1023),
  name varchar2(1023),
  icon_file_id number(32,0),
  extra_data varchar2(32767),

  create_date number(32,0),
  status varchar2(1023),
  version number(16,0),
  change_date number(32,0)
);
ALTER TABLE market_type ADD CONSTRAINT pk_market_type PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

CREATE TABLE play_event_type (
  id number(32,0),
  code varchar2(1023),
  name varchar2(1023),
  icon_file_id number(32,0),
  extra_data varchar2(32767),

  create_date number(32,0),
  status varchar2(1023),
  version number(16,0),
  change_date number(32,0)
);
ALTER TABLE play_event_type ADD CONSTRAINT pk_play_event_type PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

CREATE TABLE result_type (
  id number(32,0),
  code varchar2(1023),
  name varchar2(1023),
  icon_file_id number(32,0),
  extra_data varchar2(32767),

  create_date number(32,0),
  status varchar2(1023),
  version number(16,0),
  change_date number(32,0)
);
ALTER TABLE result_type ADD CONSTRAINT pk_result_type PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

CREATE TABLE league (
  id number(32,0),
	sport_id number(32,0),
  country_id number(32,0),
  name varchar2(1023),
  logo_file_id number(32,0),
	current_season varchar2(1023),
  standings varchar2(32767),
  statistics varchar2(32767),
  extra_data varchar2(32767),

  create_date number(32,0),
  status varchar2(1023),
  version number(16,0),
  change_date number(32,0)
);
ALTER TABLE league ADD CONSTRAINT pk_league PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

CREATE TABLE venue (
  id number(32,0),
  sport_id number(32,0),
  country_id number(32,0),
  name varchar2(1023),
  image_file_id number(32,0),
  extra_data varchar2(32767),

  create_date number(32,0),
  status varchar2(1023),
  version number(16,0),
  change_date number(32,0)
);
ALTER TABLE venue ADD CONSTRAINT pk_venue PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

CREATE TABLE player (
  id number(32,0),
  sport_id number(32,0),
  country_id number(32,0),
  name varchar2(1023),
  logo_file_id number(32,0),
  venue_id number(32,0),
  members varchar2(32767),
  extra_data varchar2(32767),

  create_date number(32,0),
  status varchar2(1023),
  version number(16,0),
  change_date number(32,0)
);
ALTER TABLE player ADD CONSTRAINT pk_player PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

CREATE TABLE person (
  id number(32,0),
  sport_id number(32,0),
  country_id number(32,0),
  person_type varchar2(1023),
  name varchar2(1023),
  image_file_id number(32,0),
  extra_data varchar2(32767),

  create_date number(32,0),
  status varchar2(1023),
  version number(16,0),
  change_date number(32,0)
);
ALTER TABLE person ADD CONSTRAINT pk_person PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

CREATE TABLE fixture (
  id number(32,0),
  sport_id number(32,0),
  country_id number(32,0),
  league_id number(32,0),
  name varchar2(1023),
  start_date number(32,0),
  fixture_status varchar2(1023),
  venue_id number(32,0),
  scoreboard varchar2(32767),
  statistics varchar2(32767),
  head_to_head varchar2(32767),
  extra_data varchar2(32767),

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

create table fixture_player (
  id number(32,0),
  fixture_id number(32,0),
  player_id number(32,0),
  position varchar2(1023),
  position_num number(16,0),
  statistics varchar2(32767),
  lineup varchar2(32767),
  extra_data varchar2(32767),

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
ALTER TABLE fixture_player ADD CONSTRAINT pk_fixture_player PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_fixture_player_fixture ON fixture_player (fixture_id) TABLESPACE app_main_index;

create table fixture_prematch_bet (
  id number(32,0),
  fixture_id number(32,0),
  market_type_id number(32,0),
  market_line varchar2(1023),
  name varchar2(1023),
  bet_status varchar2(1023),
  bet_result varchar2(1023),
  price number(16,4),

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
ALTER TABLE fixture_prematch_bet ADD CONSTRAINT pk_fixture_prematch_bet PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_fixture_prematch_bet_fixture ON fixture_prematch_bet (fixture_id) TABLESPACE app_main_index;

create table fixture_inplay_bet (
  id number(32,0),
  fixture_id number(32,0),
  market_type_id number(32,0),
  market_line varchar2(1023),
  name varchar2(1023),
  bet_status varchar2(1023),
  bet_result varchar2(1023),
  price number(16,4),

  create_date number(32,0),
  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  partition_date date default SYSDATE
)
partition by range(partition_date)
interval (numtodsinterval(7,'day'))
(partition p0 values less than
  (to_date('2024-01-01','YYYY-MM-DD'))
);
ALTER TABLE fixture_inplay_bet ADD CONSTRAINT pk_fixture_inplay_bet PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_fixture_inplay_bet_fixture ON fixture_inplay_bet (fixture_id) TABLESPACE app_main_index;

create table fixture_play_event (
  id number(32,0),
  fixture_id number(32,0),
  play_event_type_id number(32,0),
  play_event_data varchar2(32767),

  create_date number(32,0),
  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  partition_date date default SYSDATE
)
partition by range(partition_date)
interval (numtodsinterval(7,'day'))
(partition p0 values less than
  (to_date('2024-01-01','YYYY-MM-DD'))
);
ALTER TABLE fixture_play_event ADD CONSTRAINT pk_fixture_play_event PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_fixture_play_event_fixture ON fixture_play_event (fixture_id) TABLESPACE app_main_index;

create table fixture_result (
  id number(32,0),
  fixture_id number(32,0),
  result_type_id number(32,0),
  result_data varchar2(32767),

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
);
ALTER TABLE fixture_result ADD CONSTRAINT pk_fixture_result PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_fixture_result_fixture ON fixture_result (fixture_id) TABLESPACE app_main_index;

create table sport_data_map (
  id number(32,0),
  type_name varchar2(1023),
  hls_id number(32,0),
  ls_id number(32,0),
  fs_id varchar2(1023),
  is_hls_main number(1,0),
  is_ls_main number(1,0),
  is_fs_main number(1,0),

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
ALTER TABLE sport_data_map ADD CONSTRAINT pk_sport_data_map PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

/* change log tables */
create table fixture_prematch_bet_change (
  data_id number(32,0),
  change_type varchar2(1023),
  data_before varchar2(32767),
  data_after varchar2(32767),
  data_source varchar2(32767),
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
CREATE INDEX ind_fixture_prematch_bet_change_change_date ON fixture_prematch_bet_change (change_date) tablespace app_log;
CREATE INDEX ind_fixture_prematch_bet_change_data_id ON fixture_prematch_bet_change (data_id) tablespace app_log;

create table fixture_inplay_bet_change (
  data_id number(32,0),
  change_type varchar2(1023),
  data_before varchar2(32767),
  data_after varchar2(32767),
  data_source varchar2(32767),
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
CREATE INDEX ind_fixture_inplay_bet_change_change_date ON fixture_inplay_bet_change (change_date) tablespace app_log;
CREATE INDEX ind_fixture_inplay_bet_change_data_id ON fixture_inplay_bet_change (data_id) tablespace app_log;

create table data_change_d1 (
  table_name varchar2(1023),
  data_id number(32,0),
  change_type varchar2(1023),
  data_before varchar2(32767),
  data_after varchar2(32767),
  data_source varchar2(32767),
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
CREATE INDEX ind_data_change_d1_change_date ON data_change_d1 (change_date) tablespace app_log;
CREATE INDEX ind_data_change_d1_data_id ON data_change_d1 (data_id) tablespace app_log;

create table data_change_d7 (
  table_name varchar2(1023),
  data_id number(32,0),
  change_type varchar2(1023),
  data_before varchar2(32767),
  data_after varchar2(32767),
  data_source varchar2(32767),
  version number(16,0),
  change_date number(32,0),
  partition_date date default sysdate
)
partition by range(partition_date)
interval (numtodsinterval(7,'day'))
(partition p0 values less than
  (to_date('2024-01-01','YYYY-MM-DD'))
)
nologging
tablespace app_log;
CREATE INDEX ind_data_change_d7_change_date ON data_change_d7 (change_date) tablespace app_log;
CREATE INDEX ind_data_change_d7_data_id ON data_change_d7 (data_id) tablespace app_log;

create table data_change_d30 (
  table_name varchar2(1023),
  data_id number(32,0),
  change_type varchar2(1023),
  data_before varchar2(32767),
  data_after varchar2(32767),
  data_source varchar2(32767),
  version number(16,0),
  change_date number(32,0),
  partition_date date default sysdate
)
partition by range(partition_date)
interval (numtodsinterval(30,'day'))
(partition p0 values less than
  (to_date('2024-01-01','YYYY-MM-DD'))
)
nologging
tablespace app_log;
CREATE INDEX ind_data_change_d30_change_date ON data_change_d30 (change_date) tablespace app_log;
CREATE INDEX ind_data_change_d30_data_id ON data_change_d30 (data_id) tablespace app_log;

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

