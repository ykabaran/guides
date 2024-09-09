create user goalserve_main identified by ""
  default tablespace APP_MAIN
  quota unlimited on APP_MAIN
  quota unlimited on APP_MAIN_INDEX
  quota unlimited on APP_LOG;

grant connect, resource to goalserve_main;

alter session set current_schema = goalserve_main;

create table MATCH_DATA
(
  ID         NUMBER generated as identity,
  MID        NUMBER,
  PERIOD     VARCHAR2(255),
  SCORE      VARCHAR2(255),
  BALL_POS   VARCHAR2(255),
  STATE_INFO VARCHAR2(32048),
  STATE      NUMBER,
  SECONDS    VARCHAR2(255),
  UPDATED_TS VARCHAR2(20),
  CREATEDAT  TIMESTAMP(6) default systimestamp,
  UPDATEDAT  TIMESTAMP(6),
  STATUS     NUMBER       default 1
);
alter table match_data
  ADD CONSTRAINT MATCH_DATA_PK PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
create index MATCH_DATA_MID_INDEX on MATCH_DATA (MID) tablespace app_main_index;

create trigger MATCH_DATA_TRG_UPDATE_TIMESTAMP
  before update
  on MATCH_DATA
  for each row
BEGIN
  :NEW.updatedAt := SYSTIMESTAMP;
END;
/

create table STATS_DICT
(
  ID          NUMBER not null,
  NAME        VARCHAR2(255),
  NAME_TR     VARCHAR2(255),
  TEAM        VARCHAR2(2),
  BALL_POS    VARCHAR2(10),
  DESCRIPTION VARCHAR2(256),
  ATTACK_POS  FLOAT,
  MODAL_IMAGE VARCHAR2(50),
  SPORT       VARCHAR2(255)
);

alter table STATS_DICT
  ADD CONSTRAINT STATS_DICT_PK PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

create table ERRORS
(
  ID        NUMBER generated as identity,
  ERROR     VARCHAR2(32048),
  DATA      CLOB,
  CREATEDAT TIMESTAMP(6) default systimestamp
);

create table MATCHES
(
  ID            NUMBER                 not null,
  BET365ID      VARCHAR2(255),
  CORE          VARCHAR2(32048),
  SPORT         VARCHAR2(255),
  LEAGUE_ID     NUMBER,
  START_DATE    VARCHAR2(255),
  START_TS_UTC  VARCHAR2(255),
  TEAM_INFO     VARCHAR2(32048),
  BONUS         VARCHAR2(32048),
  STREAM        VARCHAR2(32048),
  STS           VARCHAR2(32048),
  STATS         VARCHAR2(32048),
  TIME_LINE     VARCHAR2(32048),
  HISTORY       VARCHAR2(32048),
  UPDATED_TS    VARCHAR2(255),
  ESPORT_ID     NUMBER,
  CREATEDAT     TIMESTAMP(9) default systimestamp,
  UPDATEDAT     TIMESTAMP(9),
  STATUS        NUMBER       default 1 not null,
  MATCH_DATA_ID NUMBER,
  ESPORT_SCORE  NUMBER(10, 3)
);

alter table MATCHES
  ADD CONSTRAINT MATCHES_PK PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

create index MATCHES_ESPORT_ID_INDEX on MATCHES (ESPORT_ID) tablespace app_main_index;

create index MATCHES_LEAGUE_ID_INDEX on MATCHES (LEAGUE_ID) tablespace app_main_index;

create trigger MATCHES_DATA_TRG_UPDATE_TIMESTAMP
  before update
  on MATCHES
  for each row
BEGIN
  :NEW.updatedAt := SYSTIMESTAMP;
END;

create table LEAGUES
(
  ID        NUMBER not null,
  CITY      VARCHAR2(255),
  NAME      VARCHAR2(255),
  CREATEDAT TIMESTAMP(6) default systimestamp,
  STATUS    NUMBER       default 1,
  SPORT     VARCHAR2(255)
);
alter table LEAGUES
  ADD CONSTRAINT LEAGUES_PK PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

create role goalserve_widget_reader;
create role goalserve_widget_writer;

grant select on ERRORS to goalserve_widget_reader;
grant select on LEAGUES to goalserve_widget_reader;
grant select on MATCH_DATA to goalserve_widget_reader;
grant select on MATCHES to goalserve_widget_reader;
grant select on STATS_DICT to goalserve_widget_reader;

grant select, insert, update on ERRORS to goalserve_widget_writer;
grant select, insert, update on LEAGUES to goalserve_widget_writer;
grant select, insert, update on MATCH_DATA to goalserve_widget_writer;
grant select, insert, update on MATCHES to goalserve_widget_writer;
grant select, insert, update on STATS_DICT to goalserve_widget_writer;
