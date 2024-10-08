create user ls_main identified by ""
  default tablespace APP_MAIN
  quota unlimited on APP_MAIN
  quota unlimited on APP_MAIN_INDEX
  quota unlimited on APP_LOG
  quota unlimited on FEED_FILE;

grant connect, resource to ls_main;
alter session set current_schema = ls_main;

create table prematch_feed_file (
  id number(32,0),
  feed_id varchar2(1023),
  file_date  number(32,0),
  file_name varchar2(1023),
  file_size number(32,0),
  file_mime_type varchar2(1023),
  file_hash varchar2(1023),
  content_meta varchar2(32767),
  file_is_clob number(1,0),
  file_body varchar2(32767),
  file_body_clob clob,
  create_date number(32,0),
  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  partition_date date default sysdate
)
TABLESPACE feed_file
nologging
LOB (file_body_clob) STORE AS (disable STORAGE IN ROW)
partition by range(partition_date)
interval (numtodsinterval(1,'day'))
(partition p0 values less than
  (to_date('2024-01-01','YYYY-MM-DD'))
);
ALTER TABLE prematch_feed_file ADD CONSTRAINT pk_prematch_feed_file PRIMARY KEY (id) USING INDEX TABLESPACE feed_file;
CREATE INDEX ind_prematch_feed_file_file_date ON prematch_feed_file (file_date) tablespace feed_file;

create role ls_prematch_feed_writer;
grant select,insert on prematch_feed_file to ls_prematch_feed_writer;

create table inplay_feed_file (
  id number(32,0),
  feed_id varchar2(1023),
  file_date  number(32,0),
  file_name varchar2(1023),
  file_size number(32,0),
  file_mime_type varchar2(1023),
  file_hash varchar2(1023),
  content_meta varchar2(32767),
  file_is_clob number(1,0),
  file_body varchar2(32767),
  file_body_clob clob,
  create_date number(32,0),
  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  partition_date date default sysdate
)
tablespace feed_file
nologging
LOB (file_body_clob) STORE AS (disable STORAGE IN ROW)
partition by range(partition_date)
interval (numtodsinterval(1,'day'))
(partition p0 values less than
  (to_date('2024-01-01','YYYY-MM-DD'))
);
ALTER TABLE inplay_feed_file ADD CONSTRAINT pk_inplay_feed_file PRIMARY KEY (id) USING INDEX TABLESPACE feed_file;
CREATE INDEX ind_inplay_feed_file_file_date ON inplay_feed_file (file_date) tablespace feed_file;

create role ls_inplay_feed_writer;
grant select,insert on inplay_feed_file to ls_inplay_feed_writer;


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
  prematch_bet_data varchar2(32767),
  inplay_bet_data varchar2(32767),
  livescore_data varchar2(32767),
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

CREATE TABLE fixture_livescore (
  id number(32,0),
  fixture_id number(32,0),
  data_name varchar2(1023),
  data_value varchar2(32767),

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

ALTER TABLE fixture_livescore ADD CONSTRAINT pk_fixture_livescore PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_fixture_livescore_fixture ON fixture_livescore (fixture_id) TABLESPACE app_main_index;

CREATE TABLE fixture_prematch_bet (
  id number(32,0),
  fixture_id number(32,0),
  bookmaker_id number(32,0),
  market_type_id number(32,0),

  market_baseline varchar2(1023),
  market_line varchar2(1023),
  name varchar2(1023),
  bet_status varchar2(1023),
  bet_settlement varchar2(1023),
  start_price number(16,4),
  current_price number(16,4),
  source_last_update_ts varchar2(1023),

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
)
ENABLE ROW MOVEMENT;

ALTER TABLE fixture_prematch_bet ADD CONSTRAINT pk_fixture_prematch_bet PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_fixture_prematch_bet_fixture ON fixture_prematch_bet (fixture_id) TABLESPACE app_main_index;

CREATE TABLE fixture_inplay_bet (
  id number(32,0),
  fixture_id number(32,0),
  bookmaker_id number(32,0),
  market_type_id number(32,0),
  
  market_baseline varchar2(1023),
  market_line varchar2(1023),
  name varchar2(1023),
  bet_status varchar2(1023),
  bet_settlement varchar2(1023),
  start_price number(16,4),
  current_price number(16,4),
  source_last_update_ts varchar2(1023),

  create_date number(32,0),
  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  partition_date date default SYSDATE
)
partition by range(partition_date)
interval (numtodsinterval(1,'day'))
(partition p0 values less than
  (to_date('2024-01-01','YYYY-MM-DD'))
);

ALTER TABLE fixture_inplay_bet ADD CONSTRAINT pk_fixture_inplay_bet PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_fixture_inplay_bet_fixture ON fixture_inplay_bet (fixture_id) TABLESPACE app_main_index;

create role ls_data_writer;
create role ls_data_reader;

GRANT SELECT, INSERT, UPDATE ON sport TO ls_data_writer;
GRANT SELECT, INSERT, UPDATE ON location TO ls_data_writer;
GRANT SELECT, INSERT, UPDATE ON bookmaker TO ls_data_writer;
GRANT SELECT, INSERT, UPDATE ON market_type TO ls_data_writer;
GRANT SELECT, INSERT, UPDATE ON league TO ls_data_writer;
GRANT SELECT, INSERT, UPDATE ON player TO ls_data_writer;
GRANT SELECT, INSERT, UPDATE ON fixture TO ls_data_writer;
GRANT SELECT, INSERT, UPDATE ON fixture_livescore TO ls_data_writer;
GRANT SELECT, INSERT, UPDATE ON fixture_prematch_bet TO ls_data_writer;
GRANT SELECT, INSERT, UPDATE ON fixture_inplay_bet TO ls_data_writer;

GRANT SELECT ON sport TO ls_data_reader;
GRANT SELECT ON location TO ls_data_reader;
GRANT SELECT ON bookmaker TO ls_data_reader;
GRANT SELECT ON market_type TO ls_data_reader;
GRANT SELECT ON league TO ls_data_reader;
GRANT SELECT ON player TO ls_data_reader;
GRANT SELECT ON fixture TO ls_data_reader;
GRANT SELECT ON fixture_livescore TO ls_data_reader;
GRANT SELECT ON fixture_prematch_bet TO ls_data_writer;
GRANT SELECT ON fixture_inplay_bet TO ls_data_writer;


