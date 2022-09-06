/* Formatted on 22/11/2019 21:42:04 (QP5 v5.276) */
CREATE TABLE admin.ddl_history_log
(
    ddl               VARCHAR2 (20),
    object_owner      VARCHAR2 (30),
    object_name       VARCHAR2 (60),
    object_type       VARCHAR2 (30),
    action_username   VARCHAR2 (30),
    action_osuser     VARCHAR2 (30),
    action_terminal   VARCHAR2 (30),
    action_date       DATE,
    ddl_sql           CLOB,
    info              CLOB
)
TABLESPACE tbsp_admin
PCTFREE 10
INITRANS 1
MAXTRANS 255;


CREATE OR REPLACE TRIGGER admin.ddl_history_tr
    BEFORE CREATE OR ALTER OR DROP OR TRUNCATE OR RENAME
    ON DATABASE
DECLARE
    v_os_user          VARCHAR2 (30);
    v_terminal         VARCHAR2 (30);
    sql_text           ora_name_list_t;
    stmt               CLOB;
    v_info             VARCHAR2 (500);
    v_account_status   VARCHAR2 (50);
BEGIN
    IF    (    ora_sysevent = 'ALTER'
           AND sys.dictionary_obj_type = 'TABLESPACE'
           AND UPPER (USER) = 'SYS')
       OR (    ora_sysevent IN ('CREATE', 'DROP', 'TRUNCATE')
           AND sys.dictionary_obj_owner = 'SYS')
       OR (sys.dictionary_obj_owner = 'DBSNMP' AND UPPER (USER) = 'DBSNMP')
    THEN
        RETURN;
    END IF;

    BEGIN
        FOR i IN 1 .. ora_sql_txt (sql_text)
        LOOP
            stmt := stmt || sql_text (i);
        END LOOP;
    EXCEPTION
        WHEN OTHERS
        THEN
            NULL;
    END;

    IF (    UPPER (sys.dictionary_obj_type) = 'USER'
        AND ora_sysevent IN ('ALTER'))
    THEN
        SELECT 'Username: ' || username || '   Old Password : ' || password,
               account_status
          INTO v_info, v_account_status
          FROM dba_users
         WHERE username = sys.dictionary_obj_name;

        IF ora_des_encrypted_password IS NULL
        THEN
            v_info := NULL;
        END IF;

        IF UPPER (stmt) LIKE '% LOCK%'
        THEN
            IF v_account_status = 'OPEN'
            THEN
                v_account_status := 'LOCKED';
                v_info :=
                       ' Username: '
                    || sys.dictionary_obj_name
                    || ' -- Account is LOCKED...';
            END IF;
        END IF;

        IF UPPER (stmt) LIKE '% UNLOCK%'
        THEN
            IF v_account_status = 'LOCKED'
            THEN
                v_account_status := 'OPEN';
                v_info :=
                       ' Username: '
                    || sys.dictionary_obj_name
                    || ' -- Account is OPENED...';
            END IF;
        END IF;
    END IF;

    IF (    ora_sysevent = 'CREATE'
        AND UPPER (sys.dictionary_obj_type) IN ('PROCEDURE',
                                                'PACKAGE',
                                                'PACKAGE BODY',
                                                'FUNCTION',
                                                'PROCEDURE',
                                                'VIEW',
                                                'TABLE'))
    THEN
        BEGIN
            v_info :=
                   'Previous Source Code :'
                || CHR (10)
                || DBMS_METADATA.get_ddl (sys.dictionary_obj_type,
                                          sys.dictionary_obj_name,
                                          sys.dictionary_obj_owner);
        EXCEPTION
            WHEN OTHERS
            THEN
                v_info := 'New Object Created';
        END;
    END IF;

    IF (    ora_sysevent = 'DROP'
        AND UPPER (sys.dictionary_obj_type) IN ('SEQUENCE',
                                                'TRIGGER',
                                                'TABLE',
                                                'PROCEDURE',
                                                'PACKAGE',
                                                'PACKAGE BODY',
                                                'FUNCTION',
                                                'PROCEDURE',
                                                'VIEW'))
    THEN
        BEGIN
            v_info :=
                   'Object Dropped... Source Code :'
                || CHR (10)
                || DBMS_METADATA.get_ddl (sys.dictionary_obj_type,
                                          sys.dictionary_obj_name,
                                          sys.dictionary_obj_owner);
        EXCEPTION
            WHEN OTHERS
            THEN
                v_info := 'Object Dropped';
        END;
    END IF;

    INSERT INTO admin.ddl_history_log
    VALUES (ora_sysevent,
            sys.dictionary_obj_owner,
            sys.dictionary_obj_name,
            sys.dictionary_obj_type,
            USER,
            SUBSTR (SYS_CONTEXT ('userenv', 'os_user'), 1, 15),
            SUBSTR (SYS_CONTEXT ('userenv', 'terminal'), 1, 15),
            SYSDATE,
            stmt,
            v_info);
EXCEPTION
    WHEN OTHERS
    THEN
        NULL;
END;