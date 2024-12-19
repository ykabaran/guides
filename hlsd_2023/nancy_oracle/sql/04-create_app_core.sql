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
