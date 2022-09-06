
show parameter archive;

alter system set log_archive_dest='c:\archive' scope=both;
-- both yapmazsan sadece memoryde degistirir, restarttan sonra eski haline doner
-- hemen degismemesi icin scope=spfile


shu immediate -- normal shutdown
shu abort -- kill process


-- database calismiyorken baglanma
sqlplus as sys
startup nomount
alter database mount; -- startup nomount
alter database archivelog; -- start archive logs
alter database noarcsqlplhivelog; -- stop archive logs
archive log list
alter database open; -- startup


log_file:
/diag/rdbms/{{globalIdentifier}}/{{sid}}/trace/alert_{{sid}}.log

control file:
/oradata/{{globalIdentifier}}/CONTROL0d.CTL

sp file:
/product/{{version}}/dbhomeXX/database/spfile{{sid}}d.ora
p file (readable):
/product/{{version}}/dbhomeXX/database/init{{sid}}d.ora