create user pa_main identified by ""
  default tablespace APP_MAIN
  quota unlimited on APP_MAIN
  quota unlimited on APP_MAIN_INDEX
  quota unlimited on APP_LOG;

grant connect, resource to pa_main;
alter session set current_schema = pa_main;

create table pa_feed_file (
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
);
ALTER TABLE pa_feed_file ADD CONSTRAINT pk_pa_feed_file PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_pa_feed_file_file_date ON pa_feed_file (file_date) tablespace APP_MAIN_INDEX;

create role pa_feed_writer;
grant select,insert on pa_feed_file to pa_feed_writer;