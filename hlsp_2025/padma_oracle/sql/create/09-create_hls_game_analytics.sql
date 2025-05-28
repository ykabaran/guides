create user hls_game_analytics identified by ""
  default tablespace APP_MAIN
  quota unlimited on APP_MAIN
  quota unlimited on APP_MAIN_INDEX;

grant connect, resource to hls_game_analytics;
alter session set current_schema = hls_game_analytics;

create table game_analytics_minutely (
  id number(32,0),
  start_date number(16,0) not null,
  end_date number(16,0) not null,

  game_id number(32,0) not null,
  house_id number(32,0) not null,
  currency_code varchar2(1023) not null,

  group_id number(32,0),
  bet_option number(32,0),
  prize_type varchar2(1023),
  bet_stake number(32,0),

  prize_rating varchar2(1023),

  user_count number(16,0) not null,
  total_count number(16,0) not null,
  total_stake number(32,0) not null,
  total_return number(32,0) not null,

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0),
  partition_date date default sysdate not null 
)
partition by range(partition_date)
interval (numtodsinterval(1,'day'))
(partition p0 values less than
  (to_date('2025-01-01','YYYY-MM-DD'))
)
enable row movement;
ALTER TABLE game_analytics_minutely ADD CONSTRAINT pk_game_analytics_minutely PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_game_analytics_minutely_start_date ON game_analytics_minutely (start_date) tablespace app_main_index;

create table game_analytics_hourly (
  id number(32,0),
  start_date number(16,0) not null,
  end_date number(16,0) not null,

  game_id number(32,0) not null,
  house_id number(32,0) not null,
  currency_code varchar2(1023) not null,

  group_id number(32,0),
  bet_option number(32,0),
  prize_type varchar2(1023),
  bet_stake number(32,0),

  prize_rating varchar2(1023),

  user_count number(16,0) not null,
  total_count number(16,0) not null,
  total_stake number(32,0) not null,
  total_return number(32,0) not null,

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0),
  partition_date date default sysdate not null 
)
partition by range(partition_date)
interval (numtodsinterval(1,'day'))
(partition p0 values less than
  (to_date('2025-01-01','YYYY-MM-DD'))
)
enable row movement;
ALTER TABLE game_analytics_hourly ADD CONSTRAINT pk_game_analytics_hourly PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_game_analytics_hourly_start_date ON game_analytics_hourly (start_date) tablespace app_main_index;

create table game_analytics_daily (
  id number(32,0),
  start_date number(16,0) not null,
  end_date number(16,0) not null,

  game_id number(32,0) not null,
  house_id number(32,0) not null,
  currency_code varchar2(1023) not null,

  group_id number(32,0),
  bet_option number(32,0),
  prize_type varchar2(1023),
  bet_stake number(32,0),

  prize_rating varchar2(1023),

  user_count number(16,0) not null,
  total_count number(16,0) not null,
  total_stake number(32,0) not null,
  total_return number(32,0) not null,

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0),
  partition_date date default sysdate not null 
)
partition by range(partition_date)
interval (numtodsinterval(7,'day'))
(partition p0 values less than
  (to_date('2025-01-01','YYYY-MM-DD'))
)
enable row movement;
ALTER TABLE game_analytics_daily ADD CONSTRAINT pk_game_analytics_daily PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_game_analytics_daily_start_date ON game_analytics_daily (start_date) tablespace app_main_index;


create table game_user_analytics_minutely (
  id number(32,0),
  start_date number(16,0) not null,
  end_date number(16,0) not null,

  user_id number(32,0) not null,
  game_id number(32,0) not null,
  house_id number(32,0) not null,
  group_id number(32,0) not null,
  prize_rating varchar2(1023) not null,

  currency_code varchar2(1023) not null,
  bet_option number(32,0) not null,
  prize_type varchar2(1023) not null,
  bet_stake number(32,0) not null,

  total_count number(16,0) not null,
  total_stake number(32,0) not null,
  total_return number(32,0) not null,

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0),
  partition_date date default sysdate not null 
)
partition by range(partition_date)
interval (numtodsinterval(1,'day'))
(partition p0 values less than
  (to_date('2025-01-01','YYYY-MM-DD'))
)
enable row movement;
ALTER TABLE game_user_analytics_minutely ADD CONSTRAINT pk_game_user_analytics_minutely PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_game_user_analytics_minutely_start_date ON game_user_analytics_minutely (start_date) tablespace app_main_index;

create table game_user_analytics_hourly (
  id number(32,0),
  start_date number(16,0) not null,
  end_date number(16,0) not null,

  user_id number(32,0) not null,
  game_id number(32,0) not null,
  house_id number(32,0) not null,
  group_id number(32,0) not null,
  prize_rating varchar2(1023) not null,

  currency_code varchar2(1023) not null,
  bet_option number(32,0) not null,
  prize_type varchar2(1023) not null,
  bet_stake number(32,0) not null,

  total_count number(16,0) not null,
  total_stake number(32,0) not null,
  total_return number(32,0) not null,

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0),
  partition_date date default sysdate not null 
)
partition by range(partition_date)
interval (numtodsinterval(1,'day'))
(partition p0 values less than
  (to_date('2025-01-01','YYYY-MM-DD'))
)
enable row movement;
ALTER TABLE game_user_analytics_hourly ADD CONSTRAINT pk_game_user_analytics_hourly PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_game_user_analytics_hourly_start_date ON game_user_analytics_hourly (start_date) tablespace app_main_index;

create table game_user_analytics_daily (
  id number(32,0),
  start_date number(16,0) not null,
  end_date number(16,0) not null,

  user_id number(32,0) not null,
  game_id number(32,0) not null,
  house_id number(32,0) not null,
  group_id number(32,0) not null,
  prize_rating varchar2(1023) not null,

  currency_code varchar2(1023) not null,
  bet_option number(32,0) not null,
  prize_type varchar2(1023) not null,
  bet_stake number(32,0) not null,

  total_count number(16,0) not null,
  total_stake number(32,0) not null,
  total_return number(32,0) not null,

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0),
  partition_date date default sysdate not null 
)
partition by range(partition_date)
interval (numtodsinterval(1,'day'))
(partition p0 values less than
  (to_date('2025-01-01','YYYY-MM-DD'))
)
enable row movement;
ALTER TABLE game_user_analytics_daily ADD CONSTRAINT pk_game_user_analytics_daily PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_game_user_analytics_daily_start_date ON game_user_analytics_daily (start_date) tablespace app_main_index;

create role hls_game_analytics_reader;
create role hls_game_analytics_writer;
create role hls_game_analytics_deleter;

grant select on game_analytics_minutely to hls_game_analytics_reader;
grant select on game_analytics_hourly to hls_game_analytics_reader;
grant select on game_analytics_daily to hls_game_analytics_reader;
grant select on game_user_analytics_minutely to hls_game_analytics_reader;
grant select on game_user_analytics_hourly to hls_game_analytics_reader;
grant select on game_user_analytics_daily to hls_game_analytics_reader;

grant select,insert,update on game_analytics_minutely to hls_game_analytics_writer;
grant select,insert,update on game_analytics_hourly to hls_game_analytics_writer;
grant select,insert,update on game_analytics_daily to hls_game_analytics_writer;
grant select,insert,update on game_user_analytics_minutely to hls_game_analytics_writer;
grant select,insert,update on game_user_analytics_hourly to hls_game_analytics_writer;
grant select,insert,update on game_user_analytics_daily to hls_game_analytics_writer;

grant select,insert,update,delete on game_analytics_minutely to hls_game_analytics_deleter;
grant select,insert,update,delete on game_analytics_hourly to hls_game_analytics_deleter;
grant select,insert,update,delete on game_analytics_daily to hls_game_analytics_deleter;
grant select,insert,update,delete on game_user_analytics_minutely to hls_game_analytics_deleter;
grant select,insert,update,delete on game_user_analytics_hourly to hls_game_analytics_deleter;
grant select,insert,update,delete on game_user_analytics_daily to hls_game_analytics_deleter;