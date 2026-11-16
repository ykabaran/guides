create user hls_rngvideo_game identified by ""
  default tablespace APP_MAIN
  quota unlimited on APP_MAIN
  quota unlimited on APP_MAIN_INDEX;

grant connect, resource to hls_rngvideo_game;
alter session set current_schema = hls_rngvideo_game;

create table game_video (
  id number(32,0),
  remote_code varchar2(1023),
  remote_time number(32,0),
  remote_game_id varchar2(1023),
  is_returned number(1,0),
  video_url varchar2(1023),
  video_file_name varchar2(1023),
  results_data varchar2(32767),

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
ALTER TABLE game_video ADD CONSTRAINT pk_game_video PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index;

create role hls_rngvideo_game_reader;
create role hls_rngvideo_game_writer;
create role hls_rngvideo_game_deleter;

grant select on game_video to hls_rngvideo_game_reader;

grant select,insert,update on game_video to hls_rngvideo_game_writer;

grant select,insert,update,delete on game_video to hls_rngvideo_game_deleter;