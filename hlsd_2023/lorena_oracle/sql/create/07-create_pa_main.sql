/* schema creation */
create user pa_main identified by ""
  default tablespace APP_MAIN
  quota unlimited on APP_MAIN
  quota unlimited on APP_MAIN_INDEX
  quota unlimited on APP_LOG;

grant connect, resource to pa_main;
alter session set current_schema = pa_main;

/* feed file tables */
create table pa_feed_file (
  id number(32,0),
  feed_id varchar2(1023),
  file_date  number(32,0),
  file_name varchar2(1023),
  file_size number(32,0),
  file_mime_type varchar2(1023),
  file_hash varchar2(1023),
  content_meta varchar2(32767),
  file_clob clob,
  create_date number(32,0),
  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  partition_date date default trunc(sysdate)
)
partition by range(partition_date)
interval (numtodsinterval(1,'day'))
(partition p0 values less than
  (to_date('2024-01-01','YYYY-MM-DD'))
);
ALTER TABLE pa_feed_file ADD CONSTRAINT pk_pa_feed_file PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_pa_feed_file_file_date ON pa_feed_file (file_date) tablespace APP_MAIN_INDEX;

/* change log tables */
create table pa_data_change_d7 (
  table_name varchar2(1023),
  data_id number(32,0),
  change_type varchar2(1023),
  data_before varchar2(32767),
  data_after varchar2(32767),
  data_source varchar2(32767),
  version number(16,0),
  change_date number(32,0),
  partition_date date default trunc(sysdate)
)
partition by range(partition_date)
interval (numtodsinterval(7,'day'))
(partition p0 values less than
  (to_date('2024-01-01','YYYY-MM-DD'))
)
tablespace app_log;
CREATE INDEX ind_pa_data_change_d7_change_date ON pa_data_change_d7 (change_date) tablespace app_log;
CREATE INDEX ind_pa_data_change_d7_data_id ON pa_data_change_d7 (data_id) tablespace app_log;

create table pa_data_change_d30 (
  table_name varchar2(1023),
  data_id number(32,0),
  change_type varchar2(1023),
  data_before varchar2(32767),
  data_after varchar2(32767),
  data_source varchar2(32767),
  version number(16,0),
  change_date number(32,0),
  partition_date date default trunc(sysdate)
)
partition by range(partition_date)
interval (numtodsinterval(30,'day'))
(partition p0 values less than
  (to_date('2024-01-01','YYYY-MM-DD'))
)
tablespace app_log;
CREATE INDEX ind_pa_data_change_d30_change_date ON pa_data_change_d30 (change_date) tablespace app_log;
CREATE INDEX ind_pa_data_change_d30_data_id ON pa_data_change_d30 (data_id) tablespace app_log;

/* permanent data tables */
create table country (
  id number(32,0),
  name varchar2(1023),
  extra_data varchar2(32767), -- json data

  create_date number(32,0),
  status varchar2(1023),
  version number(16,0),
  change_date number(32,0)
);
ALTER TABLE country ADD CONSTRAINT pk_country PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
-- log changes into pa_data_change_d30

create table venue (
  id number(32,0),
  name varchar2(1023),
  race_type varchar2(1023), -- horse/greyhound
  extra_data varchar2(32767), -- json data

  create_date number(32,0),
  status varchar2(1023),
  version number(16,0),
  change_date number(32,0)
);
ALTER TABLE venue ADD CONSTRAINT pk_venue PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
-- log changes into pa_data_change_d30

create table racer (
  id number(32,0),
  name varchar2(1023),
  racer_type varchar2(1023), -- horse/dog/jockey
  extra_data varchar2(32767), -- json data { owner, trainer, breed, origin }

  create_date number(32,0),
  status varchar2(1023),
  version number(16,0),
  change_date number(32,0)
);
ALTER TABLE racer ADD CONSTRAINT pk_racer PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
-- log changes into pa_data_change_d30

/* race related, short term data tables */
create table race (
  id number(32,0),
  venue_id number(32,0),
  race_code varchar2(1023), -- usually race time as HHmm in local tz
  start_date number(32,0),
  race_status varchar2(1023), -- dormant/going to traps/finished/abandoned etc
  race_off_time number(32,0),
  extra_data varchar2(32767), -- json data { distance, class, hurdles, track_type, handicap, trifecta, etc }
  num_runners number(32,0), -- maybe max_runners

  create_date number(32,0),
  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  partition_date date default trunc(sysdate)
)
partition by range(partition_date)
interval (numtodsinterval(30,'day'))
(partition p0 values less than
  (to_date('2024-01-01','YYYY-MM-DD'))
);
ALTER TABLE race ADD CONSTRAINT pk_race PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_race_start_date ON race (start_date) tablespace APP_MAIN_INDEX;
-- log changes into pa_data_change_d7

create table race_participant (
  id number(32,0),
  race_id number(32,0),
  racer_num number(16,0), -- trap_num or cloth_number, 0 for reserve
  racer_id number(32,0), -- null for vacant trap
  extra_data varchar2(32767), -- json data { best_time, form, withdrawal reason, jockey_id, colors }
  is_active number(1,0), -- 0 for reserve/replaced
  starting_price number(12,4),
  current_price number(12,4),
  started_race number(1,0),
  finished_race number(1,0),
  disqualified number(1,0),

  create_date number(32,0),
  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  partition_date date default trunc(sysdate)
)
partition by range(partition_date)
interval (numtodsinterval(30,'day'))
(partition p0 values less than
  (to_date('2024-01-01','YYYY-MM-DD'))
);
ALTER TABLE race_participant ADD CONSTRAINT pk_race_participant PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_race_participant_race ON race_participant (race_id) tablespace APP_MAIN_INDEX;
-- log changes into pa_data_change_d7

create table race_participant_price (
  id number(32,0),
  race_id number(32,0),
  participant_id number(32,0),
  price number(12,4),
  valid_from number(32,0),
  valid_to number(32,0), -- null if is_active = 1
  is_active number(1,0),

  create_date number(32,0),
  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  partition_date date default trunc(sysdate)
)
partition by range(partition_date)
interval (numtodsinterval(30,'day'))
(partition p0 values less than
  (to_date('2024-01-01','YYYY-MM-DD'))
);
ALTER TABLE race_participant_price ADD CONSTRAINT pk_race_participant_price PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_race_participant_price_race ON race_participant_price (race_id) tablespace APP_MAIN_INDEX;
-- log changes into pa_data_change_d7

create table race_result (
  id number(32,0),
  race_id number(32,0),
  result_code varchar2(1023), -- 1st, 2nd, 3rd, forecast, tricast, etc
  result_value varchar2(1023), -- trap_num or trap_num x trap_num
  extra_data varchar2(32767), -- json data { run_time, weight }
  is_active number(1,0),
  result_price number(12,4),

  create_date number(32,0),
  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),
  partition_date date default trunc(sysdate)
)
partition by range(partition_date)
interval (numtodsinterval(30,'day'))
(partition p0 values less than
  (to_date('2024-01-01','YYYY-MM-DD'))
);
ALTER TABLE race_result ADD CONSTRAINT pk_race_result PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;
CREATE INDEX ind_race_result_race ON race_result (race_id) tablespace APP_MAIN_INDEX;
-- log changes into pa_data_change_d7

/* data access roles */
create role pa_feed_writer;
grant select,insert on pa_feed_file to pa_feed_writer;

create role pa_feed_processor;
grant select,insert,update on country to pa_feed_processor;
grant select,insert,update on venue to pa_feed_processor;
grant select,insert,update on racer to pa_feed_processor;
grant select,insert,update on race to pa_feed_processor;
grant select,insert,update on race_participant to pa_feed_processor;
grant select,insert,update on race_participant_price to pa_feed_processor;
grant select,insert,update on race_result to pa_feed_processor;
grant select,insert on pa_data_change_d7 to pa_feed_processor;
grant select,insert on pa_data_change_d30 to pa_feed_processor;

create role pa_feed_reader;
grant select on country to pa_feed_reader;
grant select on venue to pa_feed_reader;
grant select on racer to pa_feed_reader;
grant select on race to pa_feed_reader;
grant select on race_participant to pa_feed_reader;
grant select on race_participant_price to pa_feed_reader;
grant select on race_result to pa_feed_reader;
grant select on pa_data_change_d7 to pa_feed_reader;
grant select on pa_data_change_d30 to pa_feed_reader;










