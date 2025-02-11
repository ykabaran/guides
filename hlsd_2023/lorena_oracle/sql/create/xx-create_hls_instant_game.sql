create user hls_instant_game identified by ""
  default tablespace APP_MAIN
  quota unlimited on APP_MAIN
  quota unlimited on APP_MAIN_INDEX;

grant connect, resource to hls_instant_game;
alter session set current_schema = hls_instant_game;

create table game_prize_group (
  id number(32,0),
  house_id number(32,0), -- virtual_game_house
  game_id number(32,0),
  prize_type varchar2(1023), -- normal_play, no_win_play, prize_win_play, free_spin_play, free_spin_purchase_play
  currency_id number(32,0), -- from app_core
  bet_stake number(32,0), -- integer

  data varchar2(32767), -- summary data, updated periodically
  start_date number(32,0),
  end_date number(32,0),

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0),
  partition_date date default sysdate not null 
)
partition by range(partition_date)
interval (numtodsinterval(30,'day'))
(partition p0 values less than
  (to_date('2025-01-01','YYYY-MM-DD'))
)
enable row movement;
ALTER TABLE game_prize_group ADD CONSTRAINT pk_game_prize_group PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

create table game_prize (
  id number(32,0),
  group_id number(32,0), -- game_prize_group
  bet_return number(32,0),
  data varchar2(32767),
  redemption_id number(32,0),

  status varchar2(1023), -- active, disabled, done, cancelled, errored
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0),
  partition_date date default sysdate not null 
)
partition by range(partition_date)
interval (numtodsinterval(30,'day'))
(partition p0 values less than
  (to_date('2025-01-01','YYYY-MM-DD'))
)
enable row movement;
ALTER TABLE game_prize ADD CONSTRAINT pk_game_prize PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_game_prize_group ON game_prize (group_id) tablespace app_log;

create table game_prize_redemption (
  id number(32,0),
  prize_id number(32,0),
  app_id number(32,0),
  user_id number(32,0),
  session_id number(32,0),
  contract_id number(32,0),
  trace_data varchar2(32767), -- ip address, user_agent, etc
  redemption_data varchar2(32767), -- any extra game related data
  bet_return number(32,0),

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0),
  partition_date date default sysdate not null 
)
partition by range(partition_date)
interval (numtodsinterval(30,'day'))
(partition p0 values less than
  (to_date('2025-01-01','YYYY-MM-DD'))
)
enable row movement;
ALTER TABLE game_prize_redemption ADD CONSTRAINT pk_game_prize_redemption PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_game_prize_redemption_session ON game_prize_redemption (session_id) tablespace app_main_index;
CREATE INDEX ind_game_prize_redemption_user_create_date ON game_prize_redemption (user_id, create_date) tablespace app_main_index;
CREATE INDEX ind_game_prize_redemption_change_date ON game_prize_redemption (change_date) tablespace app_main_index;

create role hls_instant_game_reader;
create role hls_instant_game_writer;
create role hls_instant_game_deleter;

grant select on game_prize_group to hls_instant_game_reader;
grant select on game_prize to hls_instant_game_reader;
grant select on game_prize_redemption to hls_instant_game_reader;

grant select,insert,update on game_prize_group to hls_instant_game_writer;
grant select,insert,update on game_prize to hls_instant_game_writer;
grant select,insert,update on game_prize_redemption to hls_instant_game_writer;

grant select,insert,update,delete on game_prize_group to hls_instant_game_deleter;
grant select,insert,update,delete on game_prize to hls_instant_game_deleter;
grant select,insert,update,delete on game_prize_redemption to hls_instant_game_deleter;