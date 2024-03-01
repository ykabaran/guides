create user fs_main identified by ""
  default tablespace APP_MAIN
  quota unlimited on APP_MAIN
  quota unlimited on APP_MAIN_INDEX
  quota unlimited on APP_LOG
  quota unlimited on FEED_FILE;

grant connect, resource to fs_main;
alter session set current_schema = fs_main;

create table fs_feed_file (
  id number(32,0),
  feed_id varchar2(1023),
  file_date  number(32,0),
  file_name varchar2(1023),
  file_size number(32,0),
  file_mime_type varchar2(1023),
  file_hash varchar2(1023),
  content_meta varchar2(32767),
  file_clob clob,
  create_date number(32,0),
  status varchar2(1023),
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
tablespace FEED_FILE;
ALTER TABLE fs_feed_file ADD CONSTRAINT pk_fs_feed_file PRIMARY KEY (id) USING INDEX TABLESPACE FEED_FILE;
CREATE INDEX ind_fs_feed_file_file_date ON fs_feed_file (file_date) tablespace FEED_FILE;

create role fs_feed_writer;
grant select,insert on fs_feed_file to fs_feed_writer;


create table league (
  id varchar2(1023),
  name varchar2(1023),
  flag_url varchar2(1023),

  create_date number(32,0),
  status varchar2(1023),
  version number(16,0),
  change_date number(32,0)
);
ALTER TABLE league ADD CONSTRAINT pk_league PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

create table team (
  id varchar2(1023),
  name varchar2(1023),
  logo_url varchar2(1023),

  create_date number(32,0),
  status varchar2(1023),
  version number(16,0),
  change_date number(32,0)
);
ALTER TABLE team ADD CONSTRAINT pk_team PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

create table fixture (
  id varchar2(1023),
  league_id varchar2(1023),
  fixture_name varchar2(1023),
  start_date number(32,0),
  home_team_id varchar2(1023),
  away_team_id varchar2(1023),

  create_date number(32,0),
  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  partition_date date default sysdate
)
partition by range(partition_date)
interval (numtodsinterval(30,'day'))
(partition p0 values less than
  (to_date('2024-01-01','YYYY-MM-DD'))
);
ALTER TABLE fixture ADD CONSTRAINT pk_fixture PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_fixture_start_date ON fixture (start_date) tablespace APP_MAIN_INDEX;


grant select,insert,update on league to fs_feed_writer;
grant select,insert,update on team to fs_feed_writer;
grant select,insert,update on fixture to fs_feed_writer;

create role fs_data_reader;
grant select on league to fs_data_reader;
grant select on team to fs_data_reader;
grant select on fixture to fs_data_reader;
