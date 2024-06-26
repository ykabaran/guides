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

create table app_secret (
  id varchar2(1023),
  category varchar2(1023), -- session_token, auth_token
  role_data varchar2(32767), -- key roles
  
  encryption_key varchar2(32767),
  signature_key varchar2(32767),
  verification_key varchar2(32767),

  start_date number(32,0),
  end_date number(32,0),
  expiration_date number(32,0),

  create_date number(32,0),
  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),

  partition_date date not null
)
partition by range(partition_date)
interval (numtodsinterval(1,'day'))
(partition p0 values less than
  (to_date('2024-01-01','YYYY-MM-DD'))
);
ALTER TABLE app_secret ADD CONSTRAINT pk_app_secret PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

create table data_change_d300 (
  id number(32,0),
  table_id number(32,0),
  data_id number(32,0),
  
  change_type varchar2(1023),
  before_data varchar2(32767),
  after_data varchar2(32767),
  source_data varchar2(32767),

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
create role app_secret_writer;

GRANT EXECUTE ON pkg_date TO PUBLIC;

grant select on localization to app_core_reader;
grant select on app_secret to app_core_reader;
grant select on data_change_d300 to app_core_reader;

grant select,insert,update on localization to app_core_writer;
grant select on app_secret to app_core_reader;
grant select,insert,update on data_change_d300 to app_core_writer;

grant select,insert,update on app_secret to app_secret_writer;
