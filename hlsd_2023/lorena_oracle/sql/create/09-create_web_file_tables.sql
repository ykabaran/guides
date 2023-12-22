alter session set current_schema = web_file;

create table file_server (
  id varchar2(1023),
  info varchar2(32767),
  status varchar2(1023),
	create_date date default sysdate
);
ALTER TABLE file_server ADD CONSTRAINT pk_file_server PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

create table web_file (
  id varchar2(1023),
  server_id varchar2(1023),
  name varchar2(1023),
  extension varchar2(1023),
  category varchar2(1023),
  path varchar2(1023),
  file_size number(32,0),
  hash varchar2(1023),
  info varchar2(32767),
  source varchar2(32767),
  status varchar2(1023),
  change_tick number(32,0),
  change_date number(32,0),
  last_sync_date number(32,0),
	create_date date default sysdate
);
ALTER TABLE web_file ADD CONSTRAINT pk_web_file PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

create table web_file_reference (
  id varchar2(1023),
  server_id varchar2(1023),
  file_id varchar2(1023),
  status varchar2(1023),
  change_tick number(32,0),
  change_date number(32,0),
  last_sync_date number(32,0),
	create_date date default sysdate
);
ALTER TABLE web_file_reference ADD CONSTRAINT pk_web_file_reference PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

GRANT SELECT ON file_server TO web_file_reader_role;
GRANT SELECT ON web_file TO web_file_reader_role;
GRANT SELECT ON web_file_reference TO web_file_reader_role;
GRANT SELECT, INSERT, UPDATE ON file_server TO web_file_writer_role;
GRANT SELECT, INSERT, UPDATE ON web_file TO web_file_writer_role;
GRANT SELECT, INSERT, UPDATE ON web_file_reference TO web_file_writer_role;

INSERT INTO APP_CORE.SYSTEM_PARAM (PARAM_OWNER, PARAM_CODE, PARAM_TYPE, PARAM_VALUE, STATUS)
VALUES (
  'web_file_server_dev', 'supported.extensions', '{ "name": "json" }', '{
  "image": [ "jpeg", "jpg", "png", "webp", "avif", "gif", "svg", "tiff" ],
  "other": [ "pdf", "zip", "rar", "txt" ]
}', 'active');

insert into file_server (id, info, status) values ('web_file_server_dev', null, 'active');
commit;

select * from web_file;
select * from web_file_reference;
select * from file_server;
