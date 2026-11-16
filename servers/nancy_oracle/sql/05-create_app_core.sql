create user app_core identified by ""
  default tablespace APP_LOG
  quota unlimited on APP_LOG
  quota unlimited on APP_LOG_INDEX;

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

create table data_change_d300 (
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
interval (numtodsinterval(300,'day'))
(partition p0 values less than
  (to_date('2024-01-01','YYYY-MM-DD'))
)
pctfree 0
nologging
tablespace app_log;
ALTER TABLE data_change_d300 ADD CONSTRAINT pk_data_change_d300 PRIMARY KEY (id) USING INDEX TABLESPACE app_log_index;
CREATE INDEX ind_data_change_d300_data_id ON data_change_d300 (data_id) tablespace app_log_index;

create role app_core_log_reader;
create role app_core_log_writer;

grant select on data_change_d300 to app_core_log_reader;
grant select, insert on data_change_d300 to app_core_log_writer;
