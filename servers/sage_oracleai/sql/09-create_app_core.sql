-- Oracle 26ai / DataGrip / sage.hlsd.com:1521/sagepdb / SYS as SYSDBA.
-- Run section 1 first. Then select and execute each complete CREATE PACKAGE
-- or CREATE PACKAGE BODY statement through its final END <name>;.
-- Run the checks before granting access. CREATE OR REPLACE updates existing code.

-- 1. Provision the schema and the local role. Existing accounts keep their
-- authentication and privileges. The packages themselves need no space quota.
DECLARE
    l_exists PLS_INTEGER;
BEGIN
    IF NVL(UPPER(SYS_CONTEXT('USERENV', 'DB_UNIQUE_NAME')), '?') <> 'SAGE'
       OR NVL(SYS_CONTEXT('USERENV', 'CON_NAME'), '?') <> 'SAGEPDB'
       OR NVL(SYS_CONTEXT('USERENV', 'ISDBA'), '?') <> 'TRUE'
    THEN
        RAISE_APPLICATION_ERROR(-20001, 'Connect to SAGEPDB on SAGE as SYSDBA.');
    END IF;

    SELECT COUNT(*) INTO l_exists FROM dba_users WHERE username = 'APP_CORE';
    IF l_exists = 0 THEN
        EXECUTE IMMEDIATE 'CREATE USER app_core NO AUTHENTICATION DEFAULT TABLESPACE app_core';
    END IF;

    SELECT COUNT(*) INTO l_exists FROM dba_roles WHERE role = 'APP_CORE_UTIL_EXEC';
    IF l_exists = 0 THEN
        EXECUTE IMMEDIATE 'CREATE ROLE app_core_util_exec';
    END IF;

    EXECUTE IMMEDIATE 'GRANT EXECUTE ON sys.dbms_random TO app_core';
END;

-- If APP_CORE will own tables or indexes, assign storage quotas when provisioning
-- those objects. For example, execute either statement if that quota is wanted.
-- ALTER USER app_core QUOTA UNLIMITED ON app_core;
-- ALTER USER app_core QUOTA UNLIMITED ON app_main_index;

-- 2. Install the packages. Offsets are fractions of a day, e.g. 3/24 for UTC+03:00.
-- With a NULL offset, DATE inputs and outputs use Asia/Nicosia wall-clock time.
CREATE OR REPLACE PACKAGE app_core.pkg_date AUTHID DEFINER AS
    FUNCTION tz_offset RETURN NUMBER;
    FUNCTION to_unixms(xdate IN DATE, xtz_offset IN NUMBER DEFAULT NULL) RETURN NUMBER;
    FUNCTION to_date(xunixms IN NUMBER, xtz_offset IN NUMBER DEFAULT NULL) RETURN DATE;
    FUNCTION now_unixms RETURN NUMBER;
END pkg_date;

CREATE OR REPLACE PACKAGE BODY app_core.pkg_date AS
    c_zone CONSTANT VARCHAR2(64) := 'Asia/Nicosia';
    c_epoch CONSTANT DATE := DATE '1970-01-01';
    c_seconds_per_day CONSTANT PLS_INTEGER := 86400;
    c_ms_per_day CONSTANT PLS_INTEGER := 86400000;

    -- Read the regional offset for a specific instant, including DST.
    FUNCTION offset_at(xinstant IN TIMESTAMP WITH TIME ZONE) RETURN NUMBER IS
        l_offset VARCHAR2(6);
        l_minutes PLS_INTEGER;
    BEGIN
        SELECT TO_CHAR(
            (CAST(xinstant AS TIMESTAMP WITH TIME ZONE) AT TIME ZONE (c_zone)),
            'TZH:TZM'
        )
        INTO l_offset
        FROM dual;

        l_minutes := TO_NUMBER(SUBSTR(l_offset, 2, 2)) * 60
                   + TO_NUMBER(SUBSTR(l_offset, 5, 2));
        IF SUBSTR(l_offset, 1, 1) = '-' THEN
            l_minutes := -l_minutes;
        END IF;

        RETURN l_minutes / 1440;
    END offset_at;

    FUNCTION tz_offset RETURN NUMBER IS
    BEGIN
        RETURN offset_at(SYSTIMESTAMP);
    END tz_offset;

    FUNCTION to_unixms(xdate IN DATE, xtz_offset IN NUMBER DEFAULT NULL) RETURN NUMBER IS
        l_utc TIMESTAMP;
    BEGIN
        IF xdate IS NULL THEN
            RETURN NULL;
        ELSIF xtz_offset IS NOT NULL THEN
            RETURN ROUND(((xdate - c_epoch) - xtz_offset) * c_ms_per_day);
        END IF;

        l_utc := SYS_EXTRACT_UTC(FROM_TZ(CAST(xdate AS TIMESTAMP), c_zone));
        RETURN ROUND((CAST(l_utc AS DATE) - c_epoch) * c_ms_per_day);
    END to_unixms;

    FUNCTION to_date(xunixms IN NUMBER, xtz_offset IN NUMBER DEFAULT NULL) RETURN DATE IS
        l_utc_date DATE;
    BEGIN
        IF xunixms IS NULL THEN
            RETURN NULL;
        END IF;

        -- DATE has whole-second resolution. Floor also handles negative epochs.
        l_utc_date := c_epoch + FLOOR(xunixms / 1000) / c_seconds_per_day;
        IF xtz_offset IS NOT NULL THEN
            RETURN l_utc_date + xtz_offset;
        END IF;

        RETURN l_utc_date + offset_at(FROM_TZ(CAST(l_utc_date AS TIMESTAMP), 'UTC'));
    END to_date;

    FUNCTION now_unixms RETURN NUMBER IS
        l_now_utc TIMESTAMP(9);
        l_elapsed INTERVAL DAY(9) TO SECOND(9);
    BEGIN
        l_now_utc := SYS_EXTRACT_UTC(SYSTIMESTAMP);
        l_elapsed := l_now_utc - TIMESTAMP '1970-01-01 00:00:00';

        RETURN FLOOR(
            EXTRACT(DAY FROM l_elapsed) * c_ms_per_day
            + EXTRACT(HOUR FROM l_elapsed) * 3600000
            + EXTRACT(MINUTE FROM l_elapsed) * 60000
            + EXTRACT(SECOND FROM l_elapsed) * 1000
        );
    END now_unixms;
END pkg_date;

CREATE OR REPLACE PACKAGE app_core.pkg_uid AUTHID DEFINER AS
    FUNCTION to_int(xuid IN VARCHAR2) RETURN NUMBER;
    FUNCTION to_string(xuid IN NUMBER) RETURN VARCHAR2;
    FUNCTION new_id RETURN NUMBER;
    FUNCTION new_id_str RETURN VARCHAR2;
    -- Decode the creation instant in the caller's current session time zone.
    FUNCTION created_at(xuid IN NUMBER) RETURN TIMESTAMP WITH TIME ZONE;
    FUNCTION created_at(xuid IN VARCHAR2) RETURN TIMESTAMP WITH TIME ZONE;
END pkg_uid;

CREATE OR REPLACE PACKAGE BODY app_core.pkg_uid AS
    c_chunk_base CONSTANT NUMBER := 281474976710656; -- 2^48
    c_hex_digits CONSTANT VARCHAR2(16) := '0123456789abcdef';

    FUNCTION to_int(xuid IN VARCHAR2) RETURN NUMBER IS
        l_hex VARCHAR2(24);
        l_digit PLS_INTEGER;
        l_value NUMBER := 0;
    BEGIN
        IF xuid IS NULL THEN
            RETURN NULL;
        ELSIF LENGTH(xuid) > 24 THEN
            RAISE_APPLICATION_ERROR(-20010, 'UID must contain 1 to 24 hexadecimal digits.');
        END IF;

        l_hex := LOWER(xuid);
        FOR i IN 1 .. LENGTH(l_hex) LOOP
            l_digit := INSTR(c_hex_digits, SUBSTR(l_hex, i, 1)) - 1;
            IF l_digit < 0 THEN
                RAISE_APPLICATION_ERROR(-20010, 'UID must contain 1 to 24 hexadecimal digits.');
            END IF;
            l_value := l_value * 16 + l_digit;
        END LOOP;

        RETURN l_value;
    END to_int;

    PROCEDURE validate_number(xuid IN NUMBER) IS
    BEGIN
        IF xuid < 0 OR xuid >= c_chunk_base * c_chunk_base OR xuid <> TRUNC(xuid) THEN
            RAISE_APPLICATION_ERROR(-20011, 'UID must be an unsigned 96-bit integer.');
        END IF;
    END validate_number;

    FUNCTION to_string(xuid IN NUMBER) RETURN VARCHAR2 IS
    BEGIN
        IF xuid IS NULL THEN
            RETURN NULL;
        END IF;

        validate_number(xuid);
        RETURN LOWER(
            LPAD(TO_CHAR(TRUNC(xuid / c_chunk_base), 'FMXXXXXXXXXXXX'), 12, '0')
            || LPAD(TO_CHAR(MOD(xuid, c_chunk_base), 'FMXXXXXXXXXXXX'), 12, '0')
        );
    END to_string;

    FUNCTION new_id RETURN NUMBER IS
        l_unixms NUMBER;
        l_random NUMBER;
    BEGIN
        l_unixms := app_core.pkg_date.now_unixms();
        l_random := TRUNC(sys.dbms_random.VALUE(0, c_chunk_base));
        RETURN l_unixms * c_chunk_base + l_random;
    END new_id;

    FUNCTION new_id_str RETURN VARCHAR2 IS
    BEGIN
        RETURN to_string(new_id());
    END new_id_str;

    FUNCTION created_at(xuid IN NUMBER) RETURN TIMESTAMP WITH TIME ZONE IS
        l_utc TIMESTAMP WITH TIME ZONE;
        l_local TIMESTAMP WITH TIME ZONE;
    BEGIN
        IF xuid IS NULL THEN
            RETURN NULL;
        END IF;

        validate_number(xuid);

        -- The upper 48 bits hold Unix milliseconds. The lower 48 are random.
        l_utc := FROM_TZ(TIMESTAMP '1970-01-01 00:00:00', 'UTC')
                 + NUMTODSINTERVAL(TRUNC(xuid / c_chunk_base) / 1000, 'SECOND');

        SELECT CAST(l_utc AS TIMESTAMP WITH TIME ZONE) AT TIME ZONE SESSIONTIMEZONE
        INTO l_local
        FROM dual;

        RETURN l_local;
    END created_at;

    FUNCTION created_at(xuid IN VARCHAR2) RETURN TIMESTAMP WITH TIME ZONE IS
    BEGIN
        RETURN created_at(to_int(xuid));
    END created_at;
END pkg_uid;

-- 3. Check compilation. Expect four VALID objects and no ERROR rows.
SELECT object_name, object_type, status
FROM dba_objects
WHERE owner = 'APP_CORE' AND object_name IN ('PKG_DATE', 'PKG_UID')
ORDER BY object_name, object_type;

SELECT name, type, line, position, text
FROM dba_errors
WHERE owner = 'APP_CORE' AND name IN ('PKG_DATE', 'PKG_UID') AND attribute = 'ERROR'
ORDER BY name, type, sequence;

-- Run this entire block. Success means the block completes without an error.
DECLARE
    l_max_uid CONSTANT NUMBER := 79228162514264337593543950335;
    l_winter CONSTANT DATE := DATE '2026-01-15';
    l_summer CONSTANT DATE := DATE '2026-07-15';
    l_uid VARCHAR2(24) := app_core.pkg_uid.new_id_str();
BEGIN
    IF app_core.pkg_date.to_unixms(DATE '1970-01-01', 0) <> 0
       OR app_core.pkg_date.to_date(-1, 0) <> DATE '1970-01-01' - 1/86400
       OR app_core.pkg_date.to_unixms(l_winter) <> app_core.pkg_date.to_unixms(l_winter, 2/24)
       OR app_core.pkg_date.to_unixms(l_summer) <> app_core.pkg_date.to_unixms(l_summer, 3/24)
       OR app_core.pkg_date.to_date(app_core.pkg_date.to_unixms(l_summer)) <> l_summer
    THEN
        RAISE_APPLICATION_ERROR(-20012, 'PKG_DATE smoke check failed.');
    END IF;

    IF app_core.pkg_uid.to_string(0) <> '000000000000000000000000'
       OR app_core.pkg_uid.to_int('FFFFFFFFFFFFFFFFFFFFFFFF') <> l_max_uid
       OR app_core.pkg_uid.to_string(l_max_uid) <> 'ffffffffffffffffffffffff'
       OR l_uid IS NULL OR LENGTH(l_uid) <> 24
       OR app_core.pkg_uid.to_string(app_core.pkg_uid.to_int(l_uid)) <> l_uid
    THEN
        RAISE_APPLICATION_ERROR(-20013, 'PKG_UID smoke check failed.');
    END IF;
END;

DECLARE
    l_numeric_uid CONSTANT NUMBER := 502184824922745066778827452;
    l_hex_uid CONSTANT VARCHAR2(24) := '019f65c5e895123456789abc';
    l_expected_utc CONSTANT TIMESTAMP := TIMESTAMP '2026-07-15 12:34:56.789';
    l_expected_local TIMESTAMP WITH TIME ZONE;
    l_from_number TIMESTAMP WITH TIME ZONE;
    l_from_string TIMESTAMP WITH TIME ZONE;
    l_null_number NUMBER;
    l_null_string VARCHAR2(24);
BEGIN
    SELECT FROM_TZ(l_expected_utc, 'UTC') AT TIME ZONE SESSIONTIMEZONE
    INTO l_expected_local
    FROM dual;

    l_from_number := app_core.pkg_uid.created_at(l_numeric_uid);
    l_from_string := app_core.pkg_uid.created_at(l_hex_uid);

    IF l_from_number IS NULL OR l_from_string IS NULL
       OR SYS_EXTRACT_UTC(l_from_number) <> l_expected_utc
       OR SYS_EXTRACT_UTC(l_from_string) <> l_expected_utc
       OR TO_CHAR(l_from_number, 'HH24:MI:SS.FF3 TZH:TZM')
          <> TO_CHAR(l_expected_local, 'HH24:MI:SS.FF3 TZH:TZM')
       OR TO_CHAR(l_from_string, 'HH24:MI:SS.FF3 TZH:TZM')
          <> TO_CHAR(l_expected_local, 'HH24:MI:SS.FF3 TZH:TZM')
       OR app_core.pkg_uid.created_at(l_null_number) IS NOT NULL
       OR app_core.pkg_uid.created_at(l_null_string) IS NOT NULL
    THEN
        RAISE_APPLICATION_ERROR(-20014, 'PKG_UID.CREATED_AT smoke check failed.');
    END IF;
END;


-- 4. After checks pass, grant access for approved callers.
GRANT EXECUTE ON app_core.pkg_date TO app_core_util_exec;
GRANT EXECUTE ON app_core.pkg_uid TO app_core_util_exec;

-- Grant the role for interactive SQL. For definer-rights stored PL/SQL, grant
-- EXECUTE on the needed package directly to the owner of the calling code.
-- GRANT app_core_util_exec TO your_application_user;
-- GRANT EXECUTE ON app_core.pkg_date TO your_application_owner;
-- GRANT EXECUTE ON app_core.pkg_uid TO your_application_owner;

-- If upgrading, inspect previous grants. CREATE OR REPLACE preserves them.
SELECT grantee, table_name, privilege
FROM dba_tab_privs
WHERE owner = 'APP_CORE' AND table_name IN ('PKG_DATE', 'PKG_UID')
ORDER BY grantee, table_name, privilege;

-- If upgrading from PUBLIC grants, migrate callers first, then revoke any
-- PUBLIC grants shown above when ready.
-- REVOKE EXECUTE ON app_core.pkg_date FROM PUBLIC;
-- REVOKE EXECUTE ON app_core.pkg_uid FROM PUBLIC;
