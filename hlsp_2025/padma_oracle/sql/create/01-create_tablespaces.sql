alter session set current_schema=SYS;

alter profile DEFAULT limit password_life_time UNLIMITED;

select * from v$log;
select * from v$logfile;
select * from DBA_DATA_FILES;
select * from SYS.DBA_TABLESPACES;

alter database datafile '/uoradata/PADMA/system01.dbf' resize 2G;
alter database datafile '/uoradata/PADMA/system01.dbf' autoextend off;
alter database datafile '/uoradata/PADMA/sysaux01.dbf' resize 4G;
alter database datafile '/uoradata/PADMA/sysaux01.dbf' autoextend off;
ALTER TABLESPACE sysaux
     ADD DATAFILE '/uoradata/PADMA/sysaux02.dbf' size 4G autoextend off;

alter database datafile '/uoradata/PADMA/users01.dbf' resize 1G;
alter database datafile '/uoradata/PADMA/users01.dbf' autoextend off;
alter database datafile '/uoradata/PADMA/undotbs01.dbf' resize 4G;
alter database datafile '/uoradata/PADMA/undotbs01.dbf' autoextend off;
ALTER TABLESPACE undotbs1
     ADD DATAFILE '/uoradata/PADMA/undotbs02.dbf' SIZE 4G AUTOEXTEND OFF;
ALTER TABLESPACE undotbs1
     ADD DATAFILE '/uoradata/PADMA/undotbs03.dbf' SIZE 4G AUTOEXTEND OFF;
ALTER TABLESPACE undotbs1
     ADD DATAFILE '/uoradata/PADMA/undotbs04.dbf' SIZE 4G AUTOEXTEND OFF;

alter database add logfile group 4 ('/uoradata/PADMA/redo04.log') size 400M;
alter database add logfile group 5 ('/uoradata/PADMA/redo05.log') size 400M;
alter database add logfile group 6 ('/uoradata/PADMA/redo06.log') size 400M;
alter database add logfile group 7 ('/uoradata/PADMA/redo07.log') size 400M;
alter database add logfile group 8 ('/uoradata/PADMA/redo08.log') size 400M;
alter system switch logfile;
alter system checkpoint;
alter database drop logfile group 1;
alter database drop logfile group 2;
alter database drop logfile group 3;

create tablespace app_log
	datafile '/uoradata/PADMA/app_log01.dbf' size 8G autoextend off
	NOLOGGING;
create tablespace app_core
	datafile '/uoradata/PADMA/app_core01.dbf' size 2G autoextend off;
create tablespace app_main
	datafile '/uoradata/PADMA/app_main01.dbf' size 8G autoextend off;
alter tablespace app_main
	add datafile '/uoradata/PADMA/app_main02.dbf' size 8G autoextend off;
alter tablespace app_main
	add datafile '/uoradata/PADMA/app_main03.dbf' size 8G autoextend off;
alter tablespace app_main
	add datafile '/uoradata/PADMA/app_main04.dbf' size 8G autoextend off;
alter tablespace app_main
   add datafile '/uoradata/PADMA/app_main05.dbf' size 8G autoextend off;
alter tablespace app_main
   add datafile '/uoradata/PADMA/app_main06.dbf' size 8G autoextend off;
create tablespace app_main_index
	datafile '/uoradata/PADMA/app_main_index01.dbf' size 8G autoextend off;
alter tablespace app_main_index
	add datafile '/uoradata/PADMA/app_main_index02.dbf' size 8G autoextend off;
alter tablespace app_main_index
   add datafile '/uoradata/PADMA/app_main_index03.dbf' size 8G autoextend off;
alter tablespace app_main_index
   add datafile '/uoradata/PADMA/app_main_index04.dbf' size 8G autoextend off;
alter tablespace app_main_index
   add datafile '/uoradata/PADMA/app_main_index05.dbf' size 8G autoextend off;
alter tablespace app_main_index
   add datafile '/uoradata/PADMA/app_main_index06.dbf' size 8G autoextend off;

select
   fs.tablespace_name                          "Tablespace",
   (df.totalspace - fs.freespace)              "Used MB",
   fs.freespace                                "Free MB",
   df.totalspace                               "Total MB",
   df.MaxSpace                               "Max MB",
   round(100 * (fs.freespace / df.totalspace)) "Curr Pct. Free",
   round(100 * ((df.MaxSpace - (df.totalspace - fs.freespace)) / df.MaxSpace)) "Max Pct. Free"
from
   (select
      tablespace_name,
      round(sum(bytes) / 1048576) TotalSpace,
      round(sum(decode(nvl(maxbytes,0),0, bytes,maxbytes)) / 1048576) MaxSpace
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