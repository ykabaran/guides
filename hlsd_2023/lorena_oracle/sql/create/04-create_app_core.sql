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

create table system_parameter (
  id number(32,0),
  category varchar2(1023),
  name varchar2(1023),
  value_type varchar2(1023),
  value varchar2(32767),

  create_date number(32,0),
  status varchar2(1023),
  version number(16,0),
  change_date number(32,0)
);
ALTER TABLE system_parameter ADD CONSTRAINT pk_system_parameter PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

create table localization (
  id number(32,0),
  reference_id varchar2(1023),
  category varchar2(1023),
  value_type varchar2(1023),
  value_en varchar2(32767),
  value_tr varchar2(32767),

  create_date number(32,0),
  status varchar2(1023),
  version number(16,0),
  change_date number(32,0)
);
ALTER TABLE localization ADD CONSTRAINT pk_localization PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

create role app_core_reader;
create role app_core_writer;

grant select on system_parameter to app_core_reader;
grant select on localization to app_core_reader;

grant select,insert,update on system_parameter to app_core_writer;
grant select,insert,update on localization to app_core_writer;
