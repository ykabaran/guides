create user app_core identified by ""
  default tablespace APP_CORE
  quota unlimited on APP_CORE
  quota unlimited on APP_MAIN_INDEX
  quota unlimited on APP_LOG;

grant connect, resource to app_core;

alter session set current_schema=app_core;

create or replace package pkg_date
as
  function tz_offset return number;

  function to_unixms(xdate in date, xtz_offset in number := null) return number;

  function to_date(xunixms in number, xtz_offset in number := null) return date;
end;

create or replace package body pkg_date
as
  function tz_offset return number
    is
    begin
      return sysdate - CAST (systimestamp at time zone 'UTC' as date);
    end;

  function to_unixms(xdate in date, xtz_offset in number := null) return number
    is
    begin
      return round((xdate - nvl(xtz_offset, tz_offset()) - date '1970-01-01') * 86400000);
    end;

  function to_date(xunixms in number, xtz_offset in number := null) return date
    is
    begin
      return date '1970-01-01' + (xunixms/86400000) + nvl(xtz_offset, tz_offset());
    end;
end;

create table app_table_meta (
  id number(32,0),
  name varchar2(1023),
  description varchar2(1023),

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
)
tablespace APP_CORE;
ALTER TABLE app_table_meta ADD CONSTRAINT pk_app_table_meta PRIMARY KEY (id) USING INDEX TABLESPACE APP_CORE;
CREATE UNIQUE INDEX unq_app_table_meta_name ON app_table_meta (name) tablespace APP_MAIN_INDEX;

create table app_permission (
  id varchar2(1023),
  name varchar2(1023),
  description varchar2(1023),
  data varchar2(32767),

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
)
tablespace APP_CORE;
ALTER TABLE app_permission ADD CONSTRAINT pk_app_permission PRIMARY KEY (id) USING INDEX TABLESPACE APP_CORE;
CREATE UNIQUE INDEX unq_app_permission_name ON app_permission (name) tablespace APP_MAIN_INDEX;

create table app_role (
  id varchar2(1023),
  name varchar2(1023),
  description varchar2(1023),
  data varchar2(32767),

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
)
tablespace APP_CORE;
ALTER TABLE app_role ADD CONSTRAINT pk_app_role PRIMARY KEY (id) USING INDEX TABLESPACE APP_CORE;
CREATE UNIQUE INDEX unq_app_role_name ON app_role (name) tablespace APP_MAIN_INDEX;

create table app_parameter (
  id number(32,0),
  name varchar2(1023),
  description varchar2(1023),
  value varchar2(32767),

  create_date number(32,0),
  status varchar2(1023),
  version number(16,0),
  change_date number(32,0)
)
tablespace APP_CORE;
ALTER TABLE app_parameter ADD CONSTRAINT pk_app_parameter PRIMARY KEY (id) USING INDEX TABLESPACE APP_CORE;
CREATE UNIQUE INDEX unq_app_parameter_name ON app_parameter (name) tablespace APP_MAIN_INDEX;

create table app_localization (
  id number(32,0),
  name varchar2(1023),
  reference_id varchar2(1023),
  value_en varchar2(32767),
  value_tr varchar2(32767),

  create_date number(32,0),
  status varchar2(1023),
  version number(16,0),
  change_date number(32,0)
)
tablespace APP_CORE;
ALTER TABLE app_localization ADD CONSTRAINT pk_app_localization PRIMARY KEY (id) USING INDEX TABLESPACE APP_CORE;
CREATE UNIQUE INDEX unq_app_localization_name ON app_localization (name) tablespace APP_MAIN_INDEX;
CREATE UNIQUE INDEX unq_app_localization_reference_id ON app_localization (reference_id) tablespace APP_MAIN_INDEX;

create table app_secret (
  id number(32,0),
  name varchar2(1023),
  data varchar2(32767),

  create_date number(32,0),
  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),

  partition_date date not null
)
partition by range(partition_date)
interval (numtodsinterval(7,'day'))
(partition p0 values less than
  (to_date('2024-01-01','YYYY-MM-DD'))
)
tablespace APP_CORE;
ALTER TABLE app_secret ADD CONSTRAINT pk_app_secret PRIMARY KEY (id) USING INDEX TABLESPACE APP_CORE;
CREATE UNIQUE INDEX unq_app_secret_name ON app_secret (name) tablespace APP_MAIN_INDEX;

GRANT EXECUTE ON pkg_date TO PUBLIC;

create role app_core_reader;
create role app_core_writer;
create role app_core_deleter;
create role app_localization_writer;
create role app_localization_deleter;
create role app_parameter_writer;
create role app_parameter_deleter;
create role app_secret_writer;

grant select on app_table_meta to app_core_reader;
grant select on app_permission to app_core_reader;
grant select on app_role to app_core_reader;
grant select on app_parameter to app_core_reader;
grant select on app_localization to app_core_reader;
grant select on app_secret to app_core_reader;

grant select,insert,update on app_table_meta to app_core_writer;
grant select,insert,update on app_permission to app_core_writer;
grant select,insert,update on app_role to app_core_writer;
grant select,insert,update,delete on app_table_meta to app_core_deleter;
grant select,insert,update,delete on app_permission to app_core_deleter;
grant select,insert,update,delete on app_role to app_core_deleter;

grant select,insert,update on app_localization to app_localization_writer;
grant select,insert,update,delete on app_localization to app_localization_deleter;

grant select,insert,update on app_parameter to app_parameter_writer;
grant select,insert,update,delete on app_parameter to app_parameter_deleter;

grant select,insert,update on app_secret to app_secret_writer;
