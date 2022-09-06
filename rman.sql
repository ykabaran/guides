rman target /

run {
backup AS COMPRESSED BACKUPSET full database format '/ubackup/rman_backup/dbf_1_%d_%T_%s_%p.bck';
SQL 'ALTER SYSTEM ARCHIVE LOG CURRENT';
backup as COMPRESSED BACKUPSET archivelog all format '/ubackup/rman_backup/arc_1_%d_%T_%s_%p.bck';
crosscheck archivelog all;
delete noprompt archivelog all completed before 'sysdate-1';
backup current controlfile format '/ubackup/rman_backup/cnt_1_%d_%T_%s_%p.bck';
backup spfile format '/ubackup/rman_backup/spf_1_%d_%T_%s_%p.bck';
crosscheck archivelog all;
}


oradim -NEW -SID instance1
set ORACLE_SID=instance1

rman target /
startup nomount
restore spfile from 'c:\backup\SPF...BCK';
	permission fail: add instance1 service account full control to C:\...\product\12.2.0\dbhome_1\database folder
create pfile from spfile
	delete *.dispatcer from pfile
create spfile from pfile
shutdown immediate
exit

rman target /
restore controlfile from "C:\backup\CNT...BCK";
alter database mount;
catalog start with '/home/oracle/Downloads'; (optional, only needed if original backup was in different folder)
	yes
restore database;
recover database;
alter database open resetlogs;
exit

run
{
set newname for datafile 1 to "/u01/data_file/system01.dbf";
set newname for datafile 3 to "/u01/data_file/sysaux01.dbf";
set newname for datafile 5 to "/u01/data_file/undotbs01.dbf";
set newname for datafile 7 to "/u01/data_file/users01.dbf";
set newname for datafile 8 to "/u01/data_file/admin01.dbf";
set newname for datafile 9 to "/u01/data_file/admin02.dbf";
restore database;
switch datafile all;
recover database;
}

restore database;
switch datafile all;
recover database;
}

*.db_file_name_convert='C:\ORACLE\ORADATA\BURAK1','/u01/data_file'
*.log_file_name_convert= 'C:\ORACLE\ORADATA\BURAK1','/u01/data_file'

restore spfile from '/home/oracle/Downloads/SPF_1_BURAK1_20191122_13_1.BCK';
restore controlfile from '/home/oracle/Downloads/CNT_1_BURAK1_20191122_12_1.BCK';

*.audit_file_dest='/u01/log'
*.audit_trail='db'
*.compatible='12.2.0'
*.control_files='/u01/data_file/control01.ctl','/u01/data_file/control02.ctl'
*.db_block_size=8192
*.db_domain='qbity.app'
*.db_name='burak1'
*.diagnostic_dest='/u01/log'
*.log_archive_dest='/u01/archive'
*.nls_language='ENGLISH'
*.nls_territory='UNITED KINGDOM'
*.open_cursors=300
*.pga_aggregate_target=625m
*.processes=320
*.remote_login_passwordfile='EXCLUSIVE'
*.sga_target=1875m
*.undo_tablespace='UNDOTBS1'

orapwd force=yes file=orapwinstance1 password=yildiz1234!


