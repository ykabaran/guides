alter database datafile '/u02/oradata/ORLC19C1/system01.dbf' autoextend on next 10M maxsize 5G;
alter database datafile '/u02/oradata/ORLC19C1/sysaux01.dbf' autoextend on next 10M maxsize 5G;
alter database datafile '/u02/oradata/ORLC19C1/users01.dbf' autoextend on next 5M maxsize 1G;
alter database datafile '/u02/oradata/ORLC19C1/undotbs01.dbf' autoextend on next 5M maxsize 5G;

create tablespace app_log
	datafile '/u02/oradata/ORLC19C1/app_log01.dbf' size 1G reuse autoextend on next 10M maxsize 10G;
create tablespace app_core
	datafile '/u02/oradata/ORLC19C1/app_core01.dbf' size 100M reuse autoextend on next 5M maxsize 1G;
create tablespace app_main
	datafile '/u02/oradata/ORLC19C1/app_main01.dbf' size 1G reuse autoextend on next 10M maxsize 10G;
alter tablespace app_main
	add datafile '/u02/oradata/ORLC19C1/app_main02.dbf' size 1G reuse autoextend on next 10M maxsize 10G;
alter tablespace app_main
	add datafile '/u02/oradata/ORLC19C1/app_main03.dbf' size 1G reuse autoextend on next 10M maxsize 10G;
create tablespace app_main_index
	datafile '/u02/oradata/ORLC19C1/app_main_index01.dbf' size 1G reuse autoextend on next 10M maxsize 10G;
alter tablespace app_main_index
	add datafile '/u02/oradata/ORLC19C1/app_main_index02.dbf' size 1G reuse autoextend on next 10M maxsize 10G;

select * from DBA_DATA_FILES;
select * from SYS.DBA_TABLESPACES;

select
   fs.tablespace_name                          "Tablespace",
   (df.totalspace - fs.freespace)              "Used MB",
   fs.freespace                                "Free MB",
   df.totalspace                               "Total MB",
   round(100 * (fs.freespace / df.totalspace)) "Pct. Free"
from
   (select
      tablespace_name,
      round(sum(bytes) / 1048576) TotalSpace
   from
      dba_data_files
   group by
      tablespace_name
   ) df,
   (select
      tablespace_name,
      round(sum(bytes) / 1048576) FreeSpace
   from
      dba_free_space
   group by
      tablespace_name
   ) fs
where
   df.tablespace_name = fs.tablespace_name;