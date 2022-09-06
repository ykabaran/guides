
select * from dba_data_files;

create tablespace tbsp_admin datafile 'C:\ORACLE\ORADATA\BURAK1\ADMIN01.DBF' size 1G;

alter tablespace tbsp_admin add datafile 'C:\ORACLE\ORADATA\BURAK1\ADMIN02.DBF' size 500M;

alter database datafile 'C:\ORACLE\ORADATA\BURAK1\ADMIN01.DBF' resize 10M;

alter database datafile 'C:\ORACLE\ORADATA\BURAK1\ADMIN02.DBF'
autoextend on
next 1M
maxsize 40M;
