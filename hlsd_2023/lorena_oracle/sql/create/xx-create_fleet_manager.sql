
create user app_fleet identified by ""
  default tablespace APP_MAIN
  quota unlimited on APP_MAIN
  quota unlimited on APP_MAIN_INDEX
  quota unlimited on APP_LOG;
grant connect, resource to app_fleet;

alter session set current_schema = app_fleet;

create table app_node (
	id number(32,0),
  name varchar2(1023),
  manager_data varchar2(32767), -- { public: {}, private: { encrypted with manager_key } }
  node_data varchar2(32767), -- json.private encrypted with node_key
  
  create_date number(32,0),
  status number(32,0), -- active, suspended, removed
  version number(16,0),
  change_date number(32,0)
);
ALTER TABLE app_node ADD CONSTRAINT pk_app_node PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

create table app_node_link (
	id number(32,0),
  server_id number(32,0),
	client_id number(32,0),
  manager_data varchar2(32767), -- json.private encrypted with manager_key
  server_data varchar2(32767), -- json.private encrypted with server_key
  client_data varchar2(32767), -- json.private encrypted with client_key
  
  create_date number(32,0),
  status number(32,0), -- active, suspended, removed
  version number(16,0),
  change_date number(32,0)
);
ALTER TABLE app_node_link ADD CONSTRAINT pk_app_node_link PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

create table data_change_d300 (
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
interval (numtodsinterval(300,'day'))
(partition p0 values less than
  (to_date('2024-01-01','YYYY-MM-DD'))
)
nologging
tablespace app_log;
ALTER TABLE data_change_d300 ADD CONSTRAINT pk_data_change_d300 PRIMARY KEY (id) USING INDEX TABLESPACE app_log;
CREATE INDEX ind_data_change_d300_change_date ON data_change_d300 (change_date) tablespace app_log;
CREATE INDEX ind_data_change_d300_data_id ON data_change_d300 (data_id) tablespace app_log;

create role app_fleet_reader;
create role app_fleet_writer;

grant select on app_node to app_fleet_reader;
grant select on app_node_link to app_fleet_reader;
grant select on data_change_d300 to app_fleet_reader;

grant select,insert,update on app_node to app_fleet_writer;
grant select,insert,update on app_node_link to app_fleet_writer;
grant select,insert,update on data_change_d300 to app_fleet_writer;