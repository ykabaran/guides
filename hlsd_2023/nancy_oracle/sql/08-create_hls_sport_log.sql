create user hls_sport_log identified by ""
  default tablespace APP_LOG
  quota unlimited on APP_LOG
  quota unlimited on APP_LOG_INDEX;

grant connect, resource to hls_sport_log;
alter session set current_schema = hls_sport_log;

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

create role hls_sport_log_writer;
create role hls_sport_log_reader;

GRANT SELECT, INSERT ON data_change_d30 TO hls_sport_log_writer;
GRANT SELECT, INSERT ON data_change_d7 TO hls_sport_log_writer;
GRANT SELECT, INSERT ON data_change_d1 TO hls_sport_log_writer;

GRANT SELECT ON data_change_d30 TO hls_sport_log_reader;
GRANT SELECT ON data_change_d7 TO hls_sport_log_reader;
GRANT SELECT ON data_change_d1 TO hls_sport_log_reader;