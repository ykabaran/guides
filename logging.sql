/* Formatted on 22/11/2019 22:14:58 (QP5 v5.276) */
CREATE TABLE admin.db_error_log
(
    sid              NUMBER,
    username         VARCHAR2 (30),
    osuser           VARCHAR2 (30),
    host_ip          VARCHAR2 (128),
    terminal         VARCHAR2 (30),
    instance_name    VARCHAR2 (30),
    errorno          NUMBER,
    ERROR_TEXT       VARCHAR2 (4000),
    error_date       DATE,
    statement        VARCHAR2 (4000),
    backtrace        VARCHAR2 (4000),
    logger_level     VARCHAR2 (100),
    logger_name      VARCHAR2 (100),
    logger_message   VARCHAR2 (4000)
)
TABLESPACE tbsp_admin
PCTFREE 10
INITRANS 1
MAXTRANS 255;

CREATE INDEX admin.db_error_log_error_date
    ON admin.db_error_log (error_date)
    TABLESPACE tbsp_admin
    PCTFREE 10
    INITRANS 2
    MAXTRANS 255;

CREATE OR REPLACE TRIGGER admin.log_errors_all
    AFTER SERVERERROR
    ON DATABASE
    WHEN (NVL (USER, 'NULL') NOT IN ('DBSNMP', 'SYS', 'SYSTEM'))
DECLARE
    sql_text   ora_name_list_t;
    stmt       VARCHAR2 (4000) := NULL;
BEGIN
    BEGIN
        IF ora_server_error (1) <> 1017
        THEN
            FOR i IN 1 .. ora_sql_txt (sql_text)
            LOOP
                stmt := stmt || sql_text (i);
            END LOOP;
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            NULL;
    END;

    INSERT INTO db_error_log (sid,
                              username,
                              osuser,
                              host_ip,
                              terminal,
                              instance_name,
                              errorno,
                              ERROR_TEXT,
                              error_date,
                              statement,
                              backtrace,
                              logger_level,
                              logger_name,
                              logger_message)
        VALUES (
                   SYS_CONTEXT ('USERENV', 'SID'),
                   USER,
                   SYS_CONTEXT ('USERENV', 'OS_USER'),
                      SYS_CONTEXT ('USERENV', 'HOST')
                   || ':'
                   || SYS_CONTEXT ('USERENV', 'IP_ADDRESS'),
                   SYS_CONTEXT ('USERENV', 'TERMINAL'),
                      SYS_CONTEXT ('USERENV', 'DB_NAME')
                   || '--Instance_Num:'
                   || SYS_CONTEXT ('USERENV', 'INSTANCE'),
                   ora_server_error (1),
                   DBMS_UTILITY.format_error_stack,
                   SYSDATE,
                   stmt,
                   DBMS_UTILITY.format_call_stack,
                   'ERROR',
                   'DB_ERROR_TRIGGER',
                   NULL);
END;