create user app_core identified by ""
  default tablespace APP_CORE
  quota unlimited on APP_CORE;

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

GRANT EXECUTE ON pkg_date TO PUBLIC;

/*
  app_object: {
    object_category: ["data_status","value_type","language","currency","localization_category"],
    data_status: ["active","disabled","healthy","expired","questionable"]
    value_type: ["string","int","decimal","json","uid","sint","unix_date","iso_date","file"]
    language: ["turkish","english"],
    currency: [{name: "try", precision: 2}],
    localization_category: [""]
  }
*/

create table app_object (
  id number(32,0),
  category varchar2(1023),
  reference_id varchar2(1023),
  name varchar2(1023),
  value varchar2(32767),

  create_date number(32,0),
  status varchar2(1023),
  version number(16,0),
  change_date number(32,0)
);
ALTER TABLE app_object ADD CONSTRAINT pk_app_object PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

create table localization (
  id number(32,0),
  category varchar2(1023),
  reference_id varchar2(1023),
  value_en varchar2(32767),
  value_tr varchar2(32767),

  create_date number(32,0),
  status varchar2(1023),
  version number(16,0),
  change_date number(32,0)
);
ALTER TABLE localization ADD CONSTRAINT pk_localization PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

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

create role app_core_reader;
create role app_core_writer;
create role app_core_admin;

grant select on app_object to app_core_reader;
grant select on localization to app_core_reader;
grant select on data_change_d300 to app_core_reader;

grant select on app_object to app_core_writer;
grant select,insert,update on localization to app_core_writer;
grant select,insert,update on data_change_d300 to app_core_writer;

grant select,insert,update app_object to app_core_admin;
grant select,insert,update on localization to app_core_admin;
grant select,insert,update on data_change_d300 to app_core_admin;
