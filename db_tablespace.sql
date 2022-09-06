/* Formatted on 18/04/2019 15:50:43 (QP5 v5.276) */
CREATE TABLESPACE ubp_perm
  DATAFILE 'D:\ORACLE\ORADATA\ORCL\UBP_PERM_01.DBF'
    SIZE 1024M
    AUTOEXTEND OFF;

  ALTER TABLESPACE ubp_perm
 ADD DATAFILE 'D:\ORACLE\ORADATA\ORCL\UBP_PERM_02.DBF'
    SIZE 1024M
    AUTOEXTEND OFF;

CREATE TEMPORARY TABLESPACE ubp_temp
  TEMPFILE 'D:\ORACLE\ORADATA\ORCL\UBP_TEMP_01.DBF'
    SIZE 1024M
    AUTOEXTEND OFF;

    CREATE USER ubp IDENTIFIED BY "AAksu323"
    DEFAULT TABLESPACE ubp_perm
  TEMPORARY TABLESPACE ubp_temp;

GRANT CONNECT TO ubp;
GRANT DBA TO ubp;

GRANT CREATE SESSION TO ubp;

GRANT CREATE ANY TABLE TO ubp;
GRANT CREATE ANY TRIGGER TO ubp;
GRANT CREATE ANY INDEX TO ubp;
GRANT CREATE ANY JOB TO ubp;
GRANT CREATE ANY PROCEDURE TO ubp;

GRANT ALTER ANY TABLE TO ubp;
GRANT ALTER ANY TRIGGER TO ubp;
GRANT ALTER ANY INDEX TO ubp;
GRANT ALTER ANY PROCEDURE TO ubp;

GRANT ADMINISTER DATABASE TRIGGER TO ubp;
GRANT CREATE EXTERNAL JOB TO ubp;

GRANT EXECUTE ON UTL_HTTP TO ubp;
GRANT EXECUTE ON DBMS_CRYPTO TO ubp;
GRANT EXECUTE ON DBMS_LOCK TO ubp;
GRANT SELECT ON v_$session TO ubp;

exp HLTT/HLS@HLS file=D:\HLTT246.dmp log=D:\HLTT246.log OWNER=HLTT ROWS=Y buffer=614400 direct=y
imp UBP/AAksu323@ORCL file=UBP.dmp log=import_ubp.log full=y

impdp UBP/AAksu323@ORCL dumpfile=UBP.dmp logfile=import_ubp.log