create user gs_main identified by ""
  default tablespace APP_MAIN
  quota unlimited on APP_MAIN
  quota unlimited on APP_MAIN_INDEX
  quota unlimited on APP_LOG
  quota unlimited on FEED_FILE;

grant connect, resource to gs_main;
alter session set current_schema = gs_main;

create table prematch_feed_file (
  id number(32,0),

  file_id varchar2(1023),
  file_name varchar2(1023),
  file_size number(32,0),
  file_date number(32,0) not null,
  file_mime_type varchar2(1023),
  file_hash varchar2(1023) not null,
  file_data varchar2(32767),
  file_is_partial number(1,0),

  file_is_clob number(1,0),
  file_body varchar2(32767),
  file_body_clob clob,

  create_date number(32,0),
  partition_date date default sysdate not null 
)
TABLESPACE feed_file
PCTFREE 0
nologging
LOB (file_body_clob) STORE AS (disable STORAGE IN ROW)
partition by range(partition_date)
interval (numtodsinterval(1,'day'))
(partition p0 values less than
  (to_date('2024-01-01','YYYY-MM-DD'))
);
ALTER TABLE prematch_feed_file ADD CONSTRAINT pk_prematch_feed_file PRIMARY KEY (id) USING INDEX TABLESPACE feed_file;
CREATE INDEX ind_prematch_feed_file_file_date ON prematch_feed_file (file_date) tablespace feed_file;

create table inplay_feed_file (
  id number(32,0),

  file_id varchar2(1023),
  file_name varchar2(1023),
  file_size number(32,0),
  file_date number(32,0) not null,
  file_mime_type varchar2(1023),
  file_hash varchar2(1023) not null,
  file_data varchar2(32767),
  file_is_partial number(1,0),

  file_is_clob number(1,0),
  file_body varchar2(32767),
  file_body_clob clob,

  create_date number(32,0),
  partition_date date default sysdate not null 
)
tablespace feed_file
PCTFREE 0
nologging
LOB (file_body_clob) STORE AS (disable STORAGE IN ROW)
partition by range(partition_date)
interval (numtodsinterval(1,'day'))
(partition p0 values less than
  (to_date('2024-01-01','YYYY-MM-DD'))
);
ALTER TABLE inplay_feed_file ADD CONSTRAINT pk_inplay_feed_file PRIMARY KEY (id) USING INDEX TABLESPACE feed_file;
CREATE INDEX ind_inplay_feed_file_file_date ON inplay_feed_file (file_date) tablespace feed_file;


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
  gs_id varchar2(1023) not null,
  name varchar2(1023) not null,

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE sport ADD CONSTRAINT pk_sport PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE UNIQUE INDEX unq_sport_gs_id ON sport (gs_id) TABLESPACE app_main_index;

CREATE TABLE location (
  id number(32,0),
  gs_id varchar2(1023) not null,
  name varchar2(1023) not null,

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE location ADD CONSTRAINT pk_location PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE UNIQUE INDEX unq_location_gs_id ON location (gs_id) TABLESPACE app_main_index;

CREATE TABLE bookmaker (
  id number(32,0),
  gs_id varchar2(1023) not null,
  name varchar2(1023) not null,

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE bookmaker ADD CONSTRAINT pk_bookmaker PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE UNIQUE INDEX unq_bookmaker_gs_id ON bookmaker (gs_id) TABLESPACE app_main_index;

CREATE TABLE market_type (
  id number(32,0),
  gs_id varchar2(1023) not null,
  name varchar2(1023) not null,

  meta_data varchar2(32767),

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE market_type ADD CONSTRAINT pk_market_type PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE UNIQUE INDEX unq_market_type_gs_id ON market_type (gs_id) TABLESPACE app_main_index;

CREATE TABLE league (
  id number(32,0),
  gs_id varchar2(1023) not null,
  sport_id number(32,0) not null,
  location_id number(32,0) not null,
  name varchar2(1023) not null,

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE league ADD CONSTRAINT pk_league PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE UNIQUE INDEX unq_league_gs_id ON league (gs_id) TABLESPACE app_main_index;

CREATE TABLE player (
  id number(32,0) not null,
  gs_id varchar2(1023) not null,
  sport_id number(32,0) not null,
  name varchar2(1023) not null,

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE player ADD CONSTRAINT pk_player PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE UNIQUE INDEX unq_player_gs_id ON player (gs_id) TABLESPACE app_main_index;

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

CREATE TABLE fixture (
  id number(32,0),
  gs_id varchar2(1023) not null,
  sport_id number(32,0) not null,
  location_id number(32,0) not null,
  league_id number(32,0) not null,

  start_date number(32,0) not null,
  fixture_status varchar2(1023),
  fixture_name varchar2(1023),

  inplay_status varchar2(1023),
  scores_status varchar2(1023),
  statistics_status varchar2(1023),
  point_by_point_status varchar2(1023),
  prematch_bets_status varchar2(1023),
  inplay_bets_status varchar2(1023),

  server_date number(32,0),

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
CREATE UNIQUE INDEX unq_fixture_gs_id ON fixture (gs_id) TABLESPACE app_main_index;
CREATE INDEX ind_fixture_start_date ON fixture (start_date) TABLESPACE app_main_index;
CREATE INDEX ind_fixture_change_date ON fixture (change_date) TABLESPACE app_main_index;

CREATE TABLE fixture_data (
  id number(32,0),
  fixture_id number(32,0) not null,
  path_id number(32,0) not null,
  value varchar2(1023),

  server_date number(32,0),

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
  gs_id varchar2(1023) not null,
  fixture_id number(32,0) not null,
  bookmaker_id number(32,0) not null,
  market_type_id number(32,0) not null,

  market_line varchar2(1023),
  bet_name varchar2(1023) not null,
  bet_status varchar2(1023),
  bet_settlement varchar2(1023),
  bet_is_main number(1,0),
  bet_is_stop number(1,0),
  current_price number(16,4),
  last_price number(16,4),

  server_date number(32,0),

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
  gs_id varchar2(1023) not null,
  fixture_id number(32,0) not null,
  bookmaker_id number(32,0) not null,
  market_type_id number(32,0) not null,

  market_line varchar2(1023),
  bet_name varchar2(1023) not null,
  bet_status varchar2(1023),
  bet_settlement varchar2(1023),
  bet_is_main number(1,0),
  bet_is_stop number(1,0),
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

create table data_change_d30 (
  id number(32,0),
  table_id number(32,0) not null,
  data_id number(32,0) not null,
  parent_id number(32,0),
  column_name varchar2(1023),
  
  change_type varchar2(1023) not null,
  before_value varchar2(32767),
  after_value varchar2(32767),
  source_data varchar2(32767),

  version number(16,0) not null,
  change_date number(32,0) not null,
  partition_date date default sysdate not null 
)
partition by range(partition_date)
interval (numtodsinterval(30,'day'))
(partition p0 values less than
  (to_date('2024-01-01','YYYY-MM-DD'))
)
pctfree 0
nologging
tablespace app_log;
ALTER TABLE data_change_d30 ADD CONSTRAINT pk_data_change_d30 PRIMARY KEY (id) USING INDEX TABLESPACE app_log;
CREATE INDEX ind_data_change_d30_data_id ON data_change_d30 (data_id) tablespace app_log;

create table data_change_d7 (
  id number(32,0),
  table_id number(32,0) not null,
  data_id number(32,0) not null,
  parent_id number(32,0),
  column_name varchar2(1023),
  
  change_type varchar2(1023) not null,
  before_value varchar2(32767),
  after_value varchar2(32767),
  source_data varchar2(32767),

  version number(16,0) not null,
  change_date number(32,0) not null,
  partition_date date default sysdate not null 
)
partition by range(partition_date)
interval (numtodsinterval(7,'day'))
(partition p0 values less than
  (to_date('2024-01-01','YYYY-MM-DD'))
)
pctfree 0
nologging
tablespace app_log;
ALTER TABLE data_change_d7 ADD CONSTRAINT pk_data_change_d7 PRIMARY KEY (id) USING INDEX TABLESPACE app_log;
CREATE INDEX ind_data_change_d7_data_id ON data_change_d7 (data_id) tablespace app_log;

create table data_change_d1 (
  id number(32,0),
  table_id number(32,0) not null,
  data_id number(32,0) not null,
  parent_id number(32,0),
  column_name varchar2(1023),
  
  change_type varchar2(1023) not null,
  before_value varchar2(32767),
  after_value varchar2(32767),
  source_data varchar2(32767),

  version number(16,0) not null,
  change_date number(32,0) not null,
  partition_date date default sysdate not null 
)
partition by range(partition_date)
interval (numtodsinterval(1,'day'))
(partition p0 values less than
  (to_date('2024-01-01','YYYY-MM-DD'))
)
pctfree 0
nologging
tablespace app_log;
ALTER TABLE data_change_d1 ADD CONSTRAINT pk_data_change_d1 PRIMARY KEY (id) USING INDEX TABLESPACE app_log;
CREATE INDEX ind_data_change_d1_data_id ON data_change_d1 (data_id) tablespace app_log;


create role gs_data_writer;
create role gs_data_reader;

GRANT SELECT, INSERT, UPDATE ON service_status TO gs_data_writer;
GRANT SELECT, INSERT, UPDATE ON sport TO gs_data_writer;
GRANT SELECT, INSERT, UPDATE ON location TO gs_data_writer;
GRANT SELECT, INSERT, UPDATE ON bookmaker TO gs_data_writer;
GRANT SELECT, INSERT, UPDATE ON market_type TO gs_data_writer;
GRANT SELECT, INSERT, UPDATE ON league TO gs_data_writer;
GRANT SELECT, INSERT, UPDATE ON player TO gs_data_writer;
GRANT SELECT, INSERT, UPDATE ON fixture_data_path TO gs_data_writer;
GRANT SELECT, INSERT, UPDATE ON fixture_data TO gs_data_writer;
GRANT SELECT, INSERT, UPDATE ON fixture_prematch_bet TO gs_data_writer;
GRANT SELECT, INSERT, UPDATE ON fixture_inplay_bet TO gs_data_writer;
grant SELECT, INSERT ON prematch_feed_file to gs_data_writer;
grant SELECT, INSERT ON inplay_feed_file to gs_data_writer;
GRANT SELECT, INSERT ON data_change_d30 TO gs_data_writer;
GRANT SELECT, INSERT ON data_change_d7 TO gs_data_writer;
GRANT SELECT, INSERT ON data_change_d1 TO gs_data_writer;

GRANT SELECT ON service_status TO gs_data_reader;
GRANT SELECT ON sport TO gs_data_reader;
GRANT SELECT ON location TO gs_data_reader;
GRANT SELECT ON bookmaker TO gs_data_reader;
GRANT SELECT ON market_type TO gs_data_reader;
GRANT SELECT ON league TO gs_data_reader;
GRANT SELECT ON player TO gs_data_reader;
GRANT SELECT ON fixture_data_path TO gs_data_reader;
GRANT SELECT ON fixture TO gs_data_reader;
GRANT SELECT ON fixture_data TO gs_data_reader;
GRANT SELECT ON fixture_prematch_bet TO gs_data_reader;
GRANT SELECT ON fixture_inplay_bet TO gs_data_reader;
grant SELECT ON prematch_feed_file to gs_data_reader;
grant SELECT ON inplay_feed_file to gs_data_reader;
GRANT SELECT ON data_change_d30 TO gs_data_reader;
GRANT SELECT ON data_change_d7 TO gs_data_reader;
GRANT SELECT ON data_change_d1 TO gs_data_reader;
