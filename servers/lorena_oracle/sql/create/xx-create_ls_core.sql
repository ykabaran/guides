create user ls_core identified by ""
  default tablespace APP_MAIN
  quota unlimited on APP_MAIN
  quota unlimited on APP_MAIN_INDEX;

grant connect, resource to ls_core;
alter session set current_schema = ls_core;


CREATE TABLE service_status (
  id number(32,0),
  name varchar2(1023) not null,
  data varchar2(32767),

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE service_status ADD CONSTRAINT pk_service_status PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE UNIQUE INDEX unq_service_status_name ON service_status (name) TABLESPACE app_main_index;

CREATE TABLE generic_enum_type (
  id number(32,0),
  name varchar2(1023),

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE generic_enum_type ADD CONSTRAINT pk_generic_enum_type PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

create table generic_enum_value (
  id number(32,0),
  type_id number(32,0),
  ls_id varchar2(1023),
  name varchar2(1023),
  code varchar2(1023),
  description varchar2(1023),

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE generic_enum_value ADD CONSTRAINT pk_generic_enum_value PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE UNIQUE INDEX unq_generic_enum_value_ls_id ON generic_enum_value (type_id, ls_id) TABLESPACE app_main_index;

CREATE TABLE location (
  id number(32,0),
  ls_id varchar2(1023) not null,
  name varchar2(1023),

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE location ADD CONSTRAINT pk_location PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE UNIQUE INDEX unq_location_ls_id ON location (ls_id) TABLESPACE app_main_index;

CREATE TABLE location_state (
  id number(32,0),
  ls_id varchar2(1023) not null,
  location_id number(32,0),
  name varchar2(1023),

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE location_state ADD CONSTRAINT pk_location_state PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE UNIQUE INDEX unq_location_state_ls_id ON location_state (ls_id) TABLESPACE app_main_index;

CREATE TABLE location_city (
  id number(32,0),
  ls_id varchar2(1023) not null,
  location_id number(32,0),
  state_id number(32,0),
  name varchar2(1023),

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE location_city ADD CONSTRAINT pk_location_city PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE UNIQUE INDEX unq_location_city_ls_id ON location_city (ls_id) TABLESPACE app_main_index;

CREATE TABLE venue (
  id number(32,0),
  ls_id varchar2(1023) not null,
  location_id number(32,0),
  state_id number(32,0),
  city_id number(32,0),
  name varchar2(1023),

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE venue ADD CONSTRAINT pk_venue PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE UNIQUE INDEX unq_venue_ls_id ON venue (ls_id) TABLESPACE app_main_index;

CREATE TABLE sport (
  id number(32,0),
  ls_id varchar2(1023) not null,
  name varchar2(1023),
  code varchar2(1023),
  period_name varchar2(1023),
  max_period_number number(16,0),

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE sport ADD CONSTRAINT pk_sport PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE UNIQUE INDEX unq_sport_ls_id ON sport (ls_id) TABLESPACE app_main_index;

CREATE TABLE sport_tour (
  id number(32,0),
  ls_id varchar2(1023) not null,
  sport_id number(32,0),
  name varchar2(1023),

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE sport_tour ADD CONSTRAINT pk_sport_tour PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE UNIQUE INDEX unq_sport_tour_ls_id ON sport_tour (ls_id) TABLESPACE app_main_index;

CREATE TABLE league (
  id number(32,0),
  ls_id varchar2(1023) not null,
  sport_id number(32,0),
  location_id number(32,0),
  name varchar2(1023),
  season varchar2(1023),

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE league ADD CONSTRAINT pk_league PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE UNIQUE INDEX unq_league_ls_id ON league (ls_id) TABLESPACE app_main_index;

CREATE TABLE league_season (
  id number(32,0),
  ls_id varchar2(1023) not null,
  name varchar2(1023),

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE league_season ADD CONSTRAINT pk_league_season PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE UNIQUE INDEX unq_league_season_ls_id ON league_season (ls_id) TABLESPACE app_main_index;

CREATE TABLE competition (
  id number(32,0),
  ls_id varchar2(1023) not null,
  name varchar2(1023),
  competition_type varchar2(1023),
  ls_track_id varchar2(1023),

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE competition ADD CONSTRAINT pk_competition PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE UNIQUE INDEX unq_competition_ls_id ON competition (ls_id) TABLESPACE app_main_index;

CREATE TABLE market_type (
  id number(32,0),
  ls_id varchar2(1023) not null,
  name varchar2(1023),
  is_settleable number(1,0),

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE market_type ADD CONSTRAINT pk_market_type PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE UNIQUE INDEX unq_market_type_ls_id ON market_type (ls_id) TABLESPACE app_main_index;

CREATE TABLE incident_type (
  id number(32,0),
  sport_id number(32,0) not null,
  ls_id varchar2(1023) not null,
  name varchar2(1023),
  description varchar2(1023),
  ls_last_update varchar2(1023),
  ls_creation_date varchar2(1023),

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE incident_type ADD CONSTRAINT pk_incident_type PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE UNIQUE INDEX unq_incident_type_ls_id ON incident_type (sport_id, ls_id) TABLESPACE app_main_index;

create table sport_period_type (
  id number(32,0),
  sport_id number(32,0) not null,
  ls_id varchar2(1023) not null,
  name varchar2(1023),
  code varchar2(1023),

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE sport_period_type ADD CONSTRAINT pk_sport_period_type PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE UNIQUE INDEX unq_sport_period_type_ls_id ON sport_period_type (sport_id, ls_id) TABLESPACE app_main_index;

CREATE TABLE participant (
  id number(32,0),
  ls_id varchar2(1023) not null,
	sport_id number(32,0),
  location_id number(32,0),
  name varchar2(1023),
  gender varchar2(1023),
  age_category varchar2(1023),
  participant_type varchar2(1023),

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE participant ADD CONSTRAINT pk_participant PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE UNIQUE INDEX unq_participant_ls_id ON participant (ls_id) TABLESPACE app_main_index;

create table fixture_data_path (
  id number(32,0),
  name varchar2(1023) not null,
  value_type varchar2(1023) not null,

  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  create_date number(32,0)
);
ALTER TABLE fixture_data_path ADD CONSTRAINT pk_fixture_data_path PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE UNIQUE INDEX unq_fixture_data_path_name ON fixture_data_path (name, value_type) TABLESPACE app_main_index;

create role ls_core_writer;
create role ls_core_reader;

GRANT SELECT, INSERT, UPDATE ON service_status TO ls_core_writer;
GRANT SELECT, INSERT, UPDATE ON generic_enum_type TO ls_core_writer;
GRANT SELECT, INSERT, UPDATE ON generic_enum_value TO ls_core_writer;
GRANT SELECT, INSERT, UPDATE ON location TO ls_core_writer;
GRANT SELECT, INSERT, UPDATE ON location_state TO ls_core_writer;
GRANT SELECT, INSERT, UPDATE ON location_city TO ls_core_writer;
GRANT SELECT, INSERT, UPDATE ON venue TO ls_core_writer;
GRANT SELECT, INSERT, UPDATE ON sport TO ls_core_writer;
GRANT SELECT, INSERT, UPDATE ON sport_tour TO ls_core_writer;
GRANT SELECT, INSERT, UPDATE ON league TO ls_core_writer;
GRANT SELECT, INSERT, UPDATE ON league_season TO ls_core_writer;
GRANT SELECT, INSERT, UPDATE ON competition TO ls_core_writer;
GRANT SELECT, INSERT, UPDATE ON market_type TO ls_core_writer;
GRANT SELECT, INSERT, UPDATE ON incident_type TO ls_core_writer;
GRANT SELECT, INSERT, UPDATE ON sport_period_type TO ls_core_writer;
GRANT SELECT, INSERT, UPDATE ON participant TO ls_core_writer;
GRANT SELECT, INSERT, UPDATE ON fixture_data_path TO ls_core_writer;

GRANT SELECT ON service_status TO ls_core_reader;
GRANT SELECT ON generic_enum_type TO ls_core_reader;
GRANT SELECT ON generic_enum_value TO ls_core_reader;
GRANT SELECT ON location TO ls_core_reader;
GRANT SELECT ON location_state TO ls_core_reader;
GRANT SELECT ON location_city TO ls_core_reader;
GRANT SELECT ON venue TO ls_core_reader;
GRANT SELECT ON sport TO ls_core_reader;
GRANT SELECT ON sport_tour TO ls_core_reader;
GRANT SELECT ON league TO ls_core_reader;
GRANT SELECT ON league_season TO ls_core_reader;
GRANT SELECT ON competition TO ls_core_reader;
GRANT SELECT ON market_type TO ls_core_reader;
GRANT SELECT ON incident_type TO ls_core_reader;
GRANT SELECT ON sport_period_type TO ls_core_reader;
GRANT SELECT ON participant TO ls_core_reader;
GRANT SELECT ON fixture_data_path TO ls_core_reader;
