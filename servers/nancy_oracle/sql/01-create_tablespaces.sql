alter session set current_schema=SYS;

alter profile DEFAULT limit password_life_time UNLIMITED;

select * from v$log;
select * from v$logfile;
select * from DBA_DATA_FILES;
select * from SYS.DBA_TABLESPACES;

alter database datafile '/uora/app/oracle/oradata/NANCY/system01.dbf' resize 2G;
alter database datafile '/uora/app/oracle/oradata/NANCY/system01.dbf' autoextend off;
alter database datafile '/uora/app/oracle/oradata/NANCY/sysaux01.dbf' resize 4G;
alter database datafile '/uora/app/oracle/oradata/NANCY/sysaux01.dbf' autoextend off;
ALTER TABLESPACE sysaux
     ADD DATAFILE '/uora/app/oracle/oradata/NANCY/sysaux02.dbf' size 4G autoextend off;

alter database datafile '/uora/app/oracle/oradata/NANCY/users01.dbf' resize 1G;
alter database datafile '/uora/app/oracle/oradata/NANCY/users01.dbf' autoextend off;
alter database datafile '/uora/app/oracle/oradata/NANCY/undotbs01.dbf' resize 4G;
alter database datafile '/uora/app/oracle/oradata/NANCY/undotbs01.dbf' autoextend off;
ALTER TABLESPACE undotbs1
     ADD DATAFILE '/uora/app/oracle/oradata/NANCY/undotbs02.dbf' SIZE 4G AUTOEXTEND OFF;
ALTER TABLESPACE undotbs1
     ADD DATAFILE '/uora/app/oracle/oradata/NANCY/undotbs03.dbf' SIZE 4G AUTOEXTEND OFF;

alter database add logfile group 4 ('/uora/app/oracle/oradata/NANCY/redo04.log') size 1G;
alter database add logfile group 5 ('/uora/app/oracle/oradata/NANCY/redo05.log') size 1G;
alter database add logfile group 6 ('/uora/app/oracle/oradata/NANCY/redo06.log') size 1G;
alter database add logfile group 7 ('/uora/app/oracle/oradata/NANCY/redo07.log') size 1G;
alter database add logfile group 8 ('/uora/app/oracle/oradata/NANCY/redo08.log') size 1G;
alter database add logfile group 9 ('/uora/app/oracle/oradata/NANCY/redo09.log') size 1G;
alter system switch logfile;
alter system checkpoint;
alter database drop logfile group 1;
alter database drop logfile group 2;
alter database drop logfile group 3;

create tablespace app_log
	datafile '/uoradata/NANCY/app_log01.dbf' size 16G autoextend off
	NOLOGGING;
alter tablespace app_log
   add datafile '/uoradata/NANCY/app_log02.dbf' size 16G autoextend off;
alter tablespace app_log
   add datafile '/uoradata/NANCY/app_log03.dbf' size 16G autoextend off;
alter tablespace app_log
   add datafile '/uoradata/NANCY/app_log04.dbf' size 16G autoextend off;
alter tablespace app_log
   add datafile '/uoradata/NANCY/app_log05.dbf' size 16G autoextend off;
alter tablespace app_log
   add datafile '/uoradata/NANCY/app_log06.dbf' size 16G autoextend off;
alter tablespace app_log
   add datafile '/uoradata/NANCY/app_log07.dbf' size 16G autoextend off;
alter tablespace app_log
   add datafile '/uoradata/NANCY/app_log08.dbf' size 16G autoextend off;
alter tablespace app_log
   add datafile '/uoradata/NANCY/app_log09.dbf' size 16G autoextend off;
alter tablespace app_log
   add datafile '/uoradata/NANCY/app_log10.dbf' size 16G autoextend off;
alter tablespace app_log
   add datafile '/uoradata/NANCY/app_log11.dbf' size 16G autoextend off;
alter tablespace app_log
   add datafile '/uoradata/NANCY/app_log12.dbf' size 16G autoextend off;
alter tablespace app_log
   add datafile '/uoradata/NANCY/app_log13.dbf' size 16G autoextend off;
alter tablespace app_log
   add datafile '/uoradata/NANCY/app_log14.dbf' size 16G autoextend off;
alter tablespace app_log
   add datafile '/uoradata/NANCY/app_log15.dbf' size 16G autoextend off;
alter tablespace app_log
   add datafile '/uoradata/NANCY/app_log16.dbf' size 16G autoextend off;
alter tablespace app_log
   add datafile '/uoradata/NANCY/app_log17.dbf' size 16G autoextend off;
alter tablespace app_log
   add datafile '/uoradata/NANCY/app_log18.dbf' size 16G autoextend off;
alter tablespace app_log
   add datafile '/uoradata/NANCY/app_log19.dbf' size 16G autoextend off;
alter tablespace app_log
   add datafile '/uoradata/NANCY/app_log20.dbf' size 16G autoextend off;

create tablespace app_log_index
	datafile '/uoradata/NANCY/app_log_index01.dbf' size 16G autoextend off
   NOLOGGING;
alter tablespace app_log_index
	add datafile '/uoradata/NANCY/app_log_index02.dbf' size 16G autoextend off;
alter tablespace app_log_index
	add datafile '/uoradata/NANCY/app_log_index03.dbf' size 16G autoextend off;
alter tablespace app_log_index
   add datafile '/uoradata/NANCY/app_log_index04.dbf' size 16G autoextend off;
alter tablespace app_log_index
   add datafile '/uoradata/NANCY/app_log_index05.dbf' size 16G autoextend off;
alter tablespace app_log_index
   add datafile '/uoradata/NANCY/app_log_index06.dbf' size 16G autoextend off;
alter tablespace app_log_index
   add datafile '/uoradata/NANCY/app_log_index07.dbf' size 16G autoextend off;
alter tablespace app_log_index
   add datafile '/uoradata/NANCY/app_log_index08.dbf' size 16G autoextend off;
alter tablespace app_log_index
   add datafile '/uoradata/NANCY/app_log_index09.dbf' size 16G autoextend off;
alter tablespace app_log_index
   add datafile '/uoradata/NANCY/app_log_index10.dbf' size 16G autoextend off;
alter tablespace app_log_index
   add datafile '/uoradata/NANCY/app_log_index11.dbf' size 16G autoextend off;
alter tablespace app_log_index
   add datafile '/uoradata/NANCY/app_log_index12.dbf' size 16G autoextend off;

create tablespace feed_file
   datafile '/uoradata/NANCY/feed_file01.dbf' size 16G autoextend off
   NOLOGGING;
alter tablespace feed_file
   add datafile '/uoradata/NANCY/feed_file02.dbf' size 16G autoextend off;
alter tablespace feed_file
   add datafile '/uoradata/NANCY/feed_file03.dbf' size 16G autoextend off;
alter tablespace feed_file
   add datafile '/uoradata/NANCY/feed_file04.dbf' size 16G autoextend off;
alter tablespace feed_file
   add datafile '/uoradata/NANCY/feed_file05.dbf' size 16G autoextend off;
alter tablespace feed_file
   add datafile '/uoradata/NANCY/feed_file06.dbf' size 16G autoextend off;
alter tablespace feed_file
   add datafile '/uoradata/NANCY/feed_file07.dbf' size 16G autoextend off;
alter tablespace feed_file
   add datafile '/uoradata/NANCY/feed_file08.dbf' size 16G autoextend off;
alter tablespace feed_file
   add datafile '/uoradata/NANCY/feed_file09.dbf' size 16G autoextend off;
alter tablespace feed_file
   add datafile '/uoradata/NANCY/feed_file10.dbf' size 16G autoextend off;
alter tablespace feed_file
   add datafile '/uoradata/NANCY/feed_file11.dbf' size 16G autoextend off;
alter tablespace feed_file
   add datafile '/uoradata/NANCY/feed_file12.dbf' size 16G autoextend off;
