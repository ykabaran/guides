
create user app_secret identified by ""
  default tablespace APP_MAIN
  quota unlimited on APP_MAIN
  quota unlimited on APP_MAIN_INDEX
  quota unlimited on APP_LOG;
grant connect, resource to app_secret;

alter session set current_schema = app_secret;

create table secret_object (
  id number(32,0),
  category_id number(32,0),
  manager_data varchar2(32767), -- { public: {}, private: { encrypted with manager_key } }
  object_data varchar2(32767), -- json.private encrypted with node_key
  
  create_date number(32,0),
  status number(32,0), -- active, suspended, removed
  version number(16,0),
  change_date number(32,0)
);
ALTER TABLE secret_object ADD CONSTRAINT pk_secret_object PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

create table data_change_d30 (
  id number(32,0),
  table_id number(32,0),
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
ALTER TABLE data_change_d30 ADD CONSTRAINT pk_data_change_d30 PRIMARY KEY (id) USING INDEX TABLESPACE app_log;
CREATE INDEX ind_data_change_d30_change_date ON data_change_d30 (change_date) tablespace app_log;
CREATE INDEX ind_data_change_d30_data_id ON data_change_d30 (data_id) tablespace app_log;

create role app_secret_reader;
create role app_secret_writer;

grant select on secret_object to app_secret_reader;
grant select on data_change_d30 to app_secret_reader;

grant select,insert,update on secret_object to app_secret_writer;
grant select,insert,update on data_change_d30 to app_secret_writer;