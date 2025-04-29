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
  data varchar2(32767) not null, -- data about what kind of game this is and it's default configs and such

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE game ADD CONSTRAINT pk_game PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE UNIQUE INDEX unq_game_code ON game (code) TABLESPACE app_main_index;

create table virtual_game_house (
  id number(32,0),
  app_id number(32,0) not null, -- some app_id in app_user.app_user table that has a virtual_game_house role
  name varchar2(1023) not null,
  data varchar2(32767) not null, -- which games are available, general configurations, etc

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE virtual_game_house ADD CONSTRAINT pk_virtual_game_house PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

create table virtual_game_house_config (
  id number(32,0),
  house_id number(32,0) not null,
  game_id number(32,0) not null,
  wallet_id number(32,0) not null, -- must be owned by house's app_id
  data varchar2(32767) not null, -- which prize groups are available, general configurations, etc

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE virtual_game_house_config ADD CONSTRAINT pk_virtual_game_house_config PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE UNIQUE INDEX unq_virtual_game_house_config ON virtual_game_house_config (house_id, game_id) TABLESPACE app_main_index;

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