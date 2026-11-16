create user ls_log identified by ""
  default tablespace APP_LOG
  quota unlimited on APP_LOG
  quota unlimited on APP_LOG_INDEX
  quota unlimited on FEED_FILE;

grant connect, resource to ls_log;
alter session set current_schema = ls_log;

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
ALTER TABLE prematch_feed_file ADD CONSTRAINT pk_prematch_feed_file PRIMARY KEY (id) USING INDEX TABLESPACE app_log_index;
CREATE INDEX ind_prematch_feed_file_file_date ON prematch_feed_file (file_date) tablespace app_log_index;

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
ALTER TABLE inplay_feed_file ADD CONSTRAINT pk_inplay_feed_file PRIMARY KEY (id) USING INDEX TABLESPACE app_log_index;
CREATE INDEX ind_inplay_feed_file_file_date ON inplay_feed_file (file_date) tablespace app_log_index;

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
ALTER TABLE data_change_d30 ADD CONSTRAINT pk_data_change_d30 PRIMARY KEY (id) USING INDEX TABLESPACE app_log_index;
CREATE INDEX ind_data_change_d30_data_id ON data_change_d30 (data_id) tablespace app_log_index;

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
ALTER TABLE data_change_d7 ADD CONSTRAINT pk_data_change_d7 PRIMARY KEY (id) USING INDEX TABLESPACE app_log_index;
CREATE INDEX ind_data_change_d7_data_id ON data_change_d7 (data_id) tablespace app_log_index;

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
ALTER TABLE data_change_d1 ADD CONSTRAINT pk_data_change_d1 PRIMARY KEY (id) USING INDEX TABLESPACE app_log_index;
CREATE INDEX ind_data_change_d1_data_id ON data_change_d1 (data_id) tablespace app_log_index;

create role ls_log_writer;
create role ls_log_reader;

grant SELECT, INSERT ON prematch_feed_file to ls_log_writer;
grant SELECT, INSERT ON inplay_feed_file to ls_log_writer;
GRANT SELECT, INSERT ON data_change_d30 TO ls_log_writer;
GRANT SELECT, INSERT ON data_change_d7 TO ls_log_writer;
GRANT SELECT, INSERT ON data_change_d1 TO ls_log_writer;

grant SELECT ON prematch_feed_file to ls_log_reader;
grant SELECT ON inplay_feed_file to ls_log_reader;
GRANT SELECT ON data_change_d30 TO ls_log_reader;
GRANT SELECT ON data_change_d7 TO ls_log_reader;
GRANT SELECT ON data_change_d1 TO ls_log_reader;
