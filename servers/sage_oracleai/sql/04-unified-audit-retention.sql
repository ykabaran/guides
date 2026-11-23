-- Oracle 26ai / DataGrip / sage.hlsd.com:1521/sagepdb / SYS as SYSDBA.
-- Run each numbered section separately. Select each entire PL/SQL block,
-- including END;, and execute the selection in an Oracle query console.

-- 1. Verify the connection and preview records older than the cutoff.
SELECT SYS_CONTEXT('USERENV', 'DB_UNIQUE_NAME') AS db_unique_name,
       SYS_CONTEXT('USERENV', 'CON_NAME') AS container_name,
       SYS_CONTEXT('USERENV', 'SESSION_USER') AS session_user,
       SYS_CONTEXT('USERENV', 'ISDBA') AS is_dba
FROM dual;

WITH cutoff AS (
    SELECT SYS_EXTRACT_UTC(SYSTIMESTAMP) - INTERVAL '30' DAY AS cutoff_utc
    FROM dual
)
SELECT c.cutoff_utc,
       (SELECT COUNT(*)
        FROM sys.unified_audit_trail a
        WHERE a.event_timestamp_utc < c.cutoff_utc) AS visible_rows_before_cutoff
FROM cutoff c;

-- Check for an existing Oracle audit purge schedule before enabling this job.
SELECT *
FROM dba_audit_mgmt_cleanup_jobs;

-- 2. Install one local job, disabled. Re-running this block keeps an existing job.
DECLARE
    l_start_date TIMESTAMP WITH TIME ZONE;
    l_job_exists PLS_INTEGER;
BEGIN
    IF NVL(UPPER(SYS_CONTEXT('USERENV', 'DB_UNIQUE_NAME')), '?') <> 'SAGE'
       OR NVL(SYS_CONTEXT('USERENV', 'CON_NAME'), '?') <> 'SAGEPDB'
       OR NVL(SYS_CONTEXT('USERENV', 'SESSION_USER'), '?') <> 'SYS'
       OR NVL(SYS_CONTEXT('USERENV', 'ISDBA'), '?') <> 'TRUE'
    THEN
        RAISE_APPLICATION_ERROR(-20001, 'Connect to SAGEPDB on SAGE as SYSDBA.');
    END IF;

    SELECT COUNT(*)
    INTO l_job_exists
    FROM dba_scheduler_jobs
    WHERE owner = 'SYS' AND job_name = 'JOB_SAGEPDB_AUDIT_RETENTION';

    IF l_job_exists = 0 THEN
        SELECT SYSTIMESTAMP AT TIME ZONE 'Asia/Nicosia'
        INTO l_start_date
        FROM dual;

        DBMS_SCHEDULER.CREATE_JOB(
            job_name        => 'SYS.JOB_SAGEPDB_AUDIT_RETENTION',
            job_type        => 'PLSQL_BLOCK',
            job_action      => q'~
                DECLARE
                    l_cutoff_utc TIMESTAMP;
                BEGIN
                    IF NVL(UPPER(SYS_CONTEXT('USERENV', 'DB_UNIQUE_NAME')), '?') <> 'SAGE'
                       OR NVL(SYS_CONTEXT('USERENV', 'CON_NAME'), '?') <> 'SAGEPDB'
                    THEN
                        RAISE_APPLICATION_ERROR(-20002, 'Audit purge is scoped to SAGEPDB on SAGE.');
                    END IF;

                    l_cutoff_utc := SYS_EXTRACT_UTC(SYSTIMESTAMP) - INTERVAL '30' DAY;

                    DBMS_AUDIT_MGMT.SET_LAST_ARCHIVE_TIMESTAMP(
                        audit_trail_type  => DBMS_AUDIT_MGMT.AUDIT_TRAIL_UNIFIED_TABLE,
                        last_archive_time => l_cutoff_utc,
                        container         => DBMS_AUDIT_MGMT.CONTAINER_CURRENT
                    );

                    -- Oracle requires the cutoff to be committed before cleanup.
                    COMMIT;

                    DBMS_AUDIT_MGMT.CLEAN_AUDIT_TRAIL(
                        audit_trail_type        => DBMS_AUDIT_MGMT.AUDIT_TRAIL_UNIFIED_TABLE,
                        use_last_arch_timestamp => TRUE,
                        container               => DBMS_AUDIT_MGMT.CONTAINER_CURRENT
                    );
                END;
            ~',
            start_date      => l_start_date,
            repeat_interval => 'FREQ=DAILY;BYHOUR=5;BYMINUTE=30;BYSECOND=0',
            enabled         => FALSE,
            auto_drop       => FALSE,
            comments        => 'Keep 30 days of database-resident unified audit records in SAGEPDB.'
        );
    END IF;
END;

-- 3. After reviewing the preview, uncomment and run this block to enable the purge.
/*
BEGIN
    IF NVL(UPPER(SYS_CONTEXT('USERENV', 'DB_UNIQUE_NAME')), '?') <> 'SAGE'
       OR NVL(SYS_CONTEXT('USERENV', 'CON_NAME'), '?') <> 'SAGEPDB'
    THEN
        RAISE_APPLICATION_ERROR(-20003, 'Enable this job in SAGEPDB on SAGE.');
    END IF;

    DBMS_SCHEDULER.ENABLE('SYS.JOB_SAGEPDB_AUDIT_RETENTION');
END;
*/

-- 4. Check the next run and the results of the most recent runs.
SELECT enabled, state, next_run_date, last_start_date
FROM dba_scheduler_jobs
WHERE owner = 'SYS' AND job_name = 'JOB_SAGEPDB_AUDIT_RETENTION';

SELECT log_date, status, error#, additional_info
FROM dba_scheduler_job_run_details
WHERE owner = 'SYS' AND job_name = 'JOB_SAGEPDB_AUDIT_RETENTION'
ORDER BY log_date DESC
FETCH FIRST 10 ROWS ONLY;
