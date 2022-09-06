create or replace directory DATA_BACKUP_DIR as 'G:\exports';

alter user system account unlock;

expdp system/123456 DIRECTORY=DATA_BACKUP_DIR dumpfile=20200424_meta.dmp CONTENT=METADATA_ONLY full=y reuse_dumpfiles=y exclude=STATISTICS
expdp system/123456 DIRECTORY=DATA_BACKUP_DIR dumpfile=xxx.dmp CONTENT=METADATA_ONLY SCHEMAS=ADMIN
expdp system/123456 DIRECTORY=DATA_BACKUP_DIR dumpfile=xxx.dmp CONTENT=DATA_ONLY
expdp HLTS/HLS DIRECTORY=DATA_BACKUP_DIR dumpfile=20200424_all.dmp CONTENT=ALL full=y
expdp system/123456 DIRECTORY=DATA_BACKUP_DIR dumpfile=xxx.dmp CONTENT=ALL TABLES=ADMIN.TBL_USERS

impdp system/123456 DIRECTORY=DATA_BACKUP_DIR dumpfile=xxx.dmp ...


create pfile from spfile;
create spfile from pfile;