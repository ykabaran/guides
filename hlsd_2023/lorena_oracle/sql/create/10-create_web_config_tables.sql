alter session set current_schema = web_config;

create table language (
	id varchar2(1023),
	name varchar2(1023),
	image_id varchar2(1023),
	list_order number(32,0),
  status varchar2(1023),
  change_tick number(32,0),
  change_date number(32,0),
  last_sync_date number(32,0),
	create_date date default sysdate
);
ALTER TABLE language ADD CONSTRAINT pk_language PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

create table translation (
	id varchar2(1023),
	category varchar2(1023),
	value_type varchar2(32767), -- string, file, html_template, string_template
	value_en varchar2(32767),
	value_tr varchar2(32767),
  status varchar2(1023),
  change_tick number(32,0),
  change_date number(32,0),
  last_sync_date number(32,0),
	create_date date default sysdate
);
ALTER TABLE translation ADD CONSTRAINT pk_translation PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

create table sport (
	id varchar2(1023),
	name_trns_id varchar2(1023),
	image_trns_id varchar2(1023),
	list_order number(32,0),
  status varchar2(1023),
  change_tick number(32,0),
  change_date number(32,0),
  last_sync_date number(32,0),
	create_date date default sysdate
);
ALTER TABLE sport ADD CONSTRAINT pk_sport PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

create table location (
	id varchar2(1023),
	name_trns_id varchar2(1023),
	image_trns_id varchar2(1023),
	list_order number(32,0),
  status varchar2(1023),
  change_tick number(32,0),
  change_date number(32,0),
  last_sync_date number(32,0),
	create_date date default sysdate
);
ALTER TABLE location ADD CONSTRAINT pk_location PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

create table league (
	id varchar2(1023),
	name_trns_id varchar2(1023),
	image_trns_id varchar2(1023),
	list_order number(32,0),
  status varchar2(1023),
  change_tick number(32,0),
  change_date number(32,0),
  last_sync_date number(32,0),
	create_date date default sysdate
);
ALTER TABLE league ADD CONSTRAINT pk_league PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

create table player (
	id varchar2(1023),
	name_trns_id varchar2(1023),
	image_trns_id varchar2(1023),
  status varchar2(1023),
  change_tick number(32,0),
  change_date number(32,0),
  last_sync_date number(32,0),
	create_date date default sysdate
);
ALTER TABLE player ADD CONSTRAINT pk_player PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

create table fixture (
	id varchar2(1023),
	fixture_date number(32,0),
	prematch_bookmaker_id varchar2(1023),
	inplay_bookmaker_id varchar2(1023),
  status varchar2(1023),
  change_tick number(32,0),
  change_date number(32,0),
  last_sync_date number(32,0),
	create_date date default sysdate,
  partition_date date
)
partition by range(partition_date)
interval (numtodsinterval(30,'day'))
(partition p0 values less than
  (to_date('2022-01-01','YYYY-MM-DD'))
)
ENABLE ROW MOVEMENT;
ALTER TABLE fixture ADD CONSTRAINT pk_fixture PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_fixture_fixture_date ON fixture (fixture_date) tablespace APP_MAIN_INDEX;

create table market_group (
	id varchar2(1023),
	name_trns_id varchar2(1023),
	image_trns_id varchar2(1023),
	list_order number(32,0),
	info varchar2(32767),
	parent_id varchar2(1023),
  status varchar2(1023),
  change_tick number(32,0),
  change_date number(32,0),
  last_sync_date number(32,0),
	create_date date default sysdate
);
ALTER TABLE market_group ADD CONSTRAINT pk_market_group PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

create table market_type (
	id varchar2(1023),
	name_trns_id varchar2(1023),
	image_trns_id varchar2(1023),
	info varchar2(32767),
	list_order number(32,0),
  status varchar2(1023),
  change_tick number(32,0),
  change_date number(32,0),
  last_sync_date number(32,0),
	create_date date default sysdate
);
ALTER TABLE market_type ADD CONSTRAINT pk_market_type PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

create table market_group_type (
	id varchar2(1023),
	market_group_id varchar2(1023),
	market_type_id varchar2(1023),
	info varchar2(32767),
	list_order number(32,0),
  status varchar2(1023),
  change_tick number(32,0),
  change_date number(32,0),
  last_sync_date number(32,0),
	create_date date default sysdate
);
ALTER TABLE market_group_type ADD CONSTRAINT pk_market_group_type PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

create table market_bet (
	id varchar2(1023),
	market_type_id varchar2(1023),
	baseline varchar2(1023),
	line varchar2(1023),
	name varchar2(1023),
	name_trns_id varchar2(1023),
	info varchar2(32767),
	list_order number(32,0),
  status varchar2(1023),
  change_tick number(32,0),
  change_date number(32,0),
  last_sync_date number(32,0),
	create_date date default sysdate
);
ALTER TABLE market_bet ADD CONSTRAINT pk_market_bet PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

grant select on translation to web_config_reader_role;
grant select on language to web_config_reader_role;
grant select on sport to web_config_reader_role;
grant select on location to web_config_reader_role;
grant select on league to web_config_reader_role;
grant select on player to web_config_reader_role;
grant select on fixture to web_config_reader_role;
grant select on market_group to web_config_reader_role;
grant select on market_type to web_config_reader_role;
grant select on market_group_type to web_config_reader_role;
grant select on market_bet to web_config_reader_role;
grant select, insert, update on translation to web_config_writer_role;
grant select, insert, update on language to web_config_writer_role;
grant select, insert, update on sport to web_config_writer_role;
grant select, insert, update on location to web_config_writer_role;
grant select, insert, update on league to web_config_writer_role;
grant select, insert, update on player to web_config_writer_role;
grant select, insert, update on fixture to web_config_writer_role;
grant select, insert, update on market_group to web_config_writer_role;
grant select, insert, update on market_type to web_config_writer_role;
grant select, insert, update on market_group_type to web_config_writer_role;
grant select, insert, update on market_bet to web_config_writer_role;







