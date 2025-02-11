create user hls_game identified by ""
  default tablespace APP_MAIN
  quota unlimited on APP_MAIN
  quota unlimited on APP_MAIN_INDEX;

grant connect, resource to hls_game;
alter session set current_schema = hls_game;

CREATE TABLE game (
  id number(32,0),
  code varchar2(1023) not null,
  name varchar2(1023) not null,

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE game ADD CONSTRAINT pk_game PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE UNIQUE INDEX unq_game_code ON game (code) TABLESPACE app_main_index;

create table virtual_game_house (
  id number(32,0),
  app_id number(32,0), -- some app_id in app_user.app_user table that has a virtual_game_house role
  name varchar2(1023),
  data varchar2(32767), -- which games are available, general configurations, etc

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE virtual_game_house ADD CONSTRAINT pk_virtual_game_house PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

create table virtual_game_house_config (
  id number(32,0),
  house_id number(32,0),
  game_id number(32,0),
  wallet_id number(32,0), -- must be owned by house's app_id
  data varchar2(32767), -- which prize groups are available, general configurations, etc

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE virtual_game_house_config ADD CONSTRAINT pk_virtual_game_house_config PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

create role hls_game_reader;
create role hls_game_writer;
create role hls_game_deleter;

grant select on game to hls_game_reader;
grant select on virtual_game_house to hls_game_reader;
grant select on virtual_game_house_config to hls_game_reader;

grant select,insert,update on game to hls_game_writer;
grant select,insert,update on virtual_game_house to hls_game_writer;
grant select,insert,update on virtual_game_house_config to hls_game_writer;

grant select,insert,update,delete on game to hls_game_deleter;
grant select,insert,update,delete on virtual_game_house to hls_game_deleter;
grant select,insert,update,delete on virtual_game_house_config to hls_game_deleter;