-- ==========================================================================
-- 02_incremental_data.sql
-- Sets up ongoing data inserts into PROD_RAW_DB to simulate daily source
-- system activity. Run after 01_historical_data_generation.sql.
--
-- What this script does:
--   1. Enables CHANGE_TRACKING on PROV and VENDOR so that downstream
--      Snowflake Dynamic Tables can track row-level deltas.
--   2. Creates a stored procedure (INSERT_INCREMENTAL_DATA) that inserts
--      ~200 new records per call into PROV, VENDOR, and VENDOR_PROVIDER_REF,
--      continuing from each table's current max key.
--   3. Creates a scheduled Task that calls the procedure daily at 8am MT.
--      A commented-out block below shows how to switch to every 2 hours.
-- ==========================================================================

USE ROLE SYSADMIN;
USE DATABASE PROD_RAW_DB;

-- --------------------------------------------------------------------------
-- Enable change tracking on source tables in all three environments.
-- Required for dbt dynamic_table models (refresh_mode = INCREMENTAL).
-- The clones in 02 are made before this runs, so they need explicit alters.
-- --------------------------------------------------------------------------
ALTER TABLE PROD_RAW_DB.ORACLE.PROV   SET CHANGE_TRACKING = TRUE;
ALTER TABLE PROD_RAW_DB.ORACLE.VENDOR SET CHANGE_TRACKING = TRUE;
ALTER TABLE DEV_RAW_DB.ORACLE.PROV    SET CHANGE_TRACKING = TRUE;
ALTER TABLE DEV_RAW_DB.ORACLE.VENDOR  SET CHANGE_TRACKING = TRUE;
ALTER TABLE TEST_RAW_DB.ORACLE.PROV   SET CHANGE_TRACKING = TRUE;
ALTER TABLE TEST_RAW_DB.ORACLE.VENDOR SET CHANGE_TRACKING = TRUE;

-- --------------------------------------------------------------------------
-- Stored procedure: INSERT_INCREMENTAL_DATA
-- Inserts ~75 new providers, ~50 new vendors, and ~100 new vendor-provider
-- links into PROD_RAW_DB on each call.  All new rows get LAST_MODIFIED_DATE
-- = CURRENT_DATE() so the dbt incremental watermark picks them up.
-- --------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE PROD_RAW_DB.PUBLIC.INSERT_INCREMENTAL_DATA()
  RETURNS VARCHAR
  LANGUAGE SQL
  EXECUTE AS OWNER
AS
$$
DECLARE
    max_prov      NUMBER;
    max_vendor    NUMBER;
    max_vpref     NUMBER;
    prov_batch    NUMBER DEFAULT 75;
    vendor_batch  NUMBER DEFAULT 50;
    vpref_batch   NUMBER DEFAULT 100;
BEGIN
    -- -----------------------------------------------------------------------
    -- Capture current max keys so new rows continue the sequence cleanly
    -- -----------------------------------------------------------------------
    SELECT COALESCE(MAX(PROV_REC_ID), 0)
      INTO :max_prov
      FROM PROD_RAW_DB.ORACLE.PROV;

    SELECT COALESCE(MAX(TO_NUMBER(SUBSTRING(VENDOR_ID, 5))), 0)
      INTO :max_vendor
      FROM PROD_RAW_DB.ORACLE.VENDOR;

    SELECT COALESCE(MAX(VEN_PROV_KEY), 0)
      INTO :max_vpref
      FROM PROD_RAW_DB.ORACLE.VENDOR_PROVIDER_REF;

    -- -----------------------------------------------------------------------
    -- New providers  (~75 rows)
    -- -----------------------------------------------------------------------
    INSERT INTO PROD_RAW_DB.ORACLE.PROV (
        PROV_ID, PROV_REC_ID, PROV_TYPE, COUNTY, AREA, ACCESSIBLE, GENDER,
        CHANGED_DATE, "OP#", LAST_MODIFIED_DATE, LAST_MODIFIED_BY, DOB,
        QASP_LEVEL, CREDENTIALING_FLAG, HOSPITAL_ACCREDITATION_FLAG, VIP_FLAG
    )
    SELECT
        'PRV-' || LPAD((:max_prov + rn)::VARCHAR, 8, '0')             AS PROV_ID,
        :max_prov + rn                                                  AS PROV_REC_ID,
        CASE MOD(rn,5) WHEN 0 THEN 'INDIVIDUAL' WHEN 1 THEN 'ORGANIZATION'
                       WHEN 2 THEN 'FACILITY'   WHEN 3 THEN 'ANCILLARY'
                       ELSE 'GROUP' END                                AS PROV_TYPE,
        CASE MOD(rn,10)
            WHEN 0 THEN 'LOS ANGELES'     WHEN 1 THEN 'ORANGE'
            WHEN 2 THEN 'SAN DIEGO'       WHEN 3 THEN 'RIVERSIDE'
            WHEN 4 THEN 'SAN BERNARDINO'  WHEN 5 THEN 'VENTURA'
            WHEN 6 THEN 'SANTA BARBARA'   WHEN 7 THEN 'KERN'
            WHEN 8 THEN 'SAN LUIS OBISPO' ELSE 'IMPERIAL'
        END                                                            AS COUNTY,
        CASE MOD(rn,4) WHEN 0 THEN 'NORTH' WHEN 1 THEN 'SOUTH'
                       WHEN 2 THEN 'EAST'  ELSE 'WEST' END           AS AREA,
        CASE MOD(rn,2) WHEN 0 THEN 'Y' ELSE 'N' END                  AS ACCESSIBLE,
        CASE MOD(rn,3) WHEN 0 THEN 'M' WHEN 1 THEN 'F' ELSE 'U' END AS GENDER,
        TO_VARCHAR(CURRENT_DATE(), 'YYYY-MM-DD')                      AS CHANGED_DATE,
        MOD(rn,99) + 1                                                 AS "OP#",
        TO_VARCHAR(CURRENT_DATE(), 'YYYY-MM-DD')                      AS LAST_MODIFIED_DATE,
        'DAILY_TASK'                                                   AS LAST_MODIFIED_BY,
        DATEADD('day', -(MOD(rn,18250) + 7300), CURRENT_DATE())       AS DOB,
        MOD(rn,5) + 1                                                  AS QASP_LEVEL,
        CASE MOD(rn,3) WHEN 0 THEN 'ACTIVE'
                       WHEN 1 THEN 'PENDING'
                       ELSE 'EXPIRED' END                             AS CREDENTIALING_FLAG,
        (MOD(rn,4) = 0)                                               AS HOSPITAL_ACCREDITATION_FLAG,
        (MOD(rn,10) = 0)                                              AS VIP_FLAG
    FROM (
        SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS rn
        FROM TABLE(GENERATOR(ROWCOUNT => 75))
    );

    -- -----------------------------------------------------------------------
    -- New vendors  (~50 rows)
    -- -----------------------------------------------------------------------
    INSERT INTO PROD_RAW_DB.ORACLE.VENDOR (
        VENDOR_ID, FIRST_NAME, LAST_NAME, EFFECTIVE_DATE, END_DATE,
        LAST_MODIFIED_BY, LAST_MODIFIED_DATE, CONTRACT_FLAG,
        CONTRACT_EFF_DATE, CONTRACT_END_DATE
    )
    SELECT
        'VEN-' || LPAD((:max_vendor + rn)::VARCHAR, 8, '0')           AS VENDOR_ID,
        CASE MOD(rn,8)
            WHEN 0 THEN 'JAMES'    WHEN 1 THEN 'MARY'
            WHEN 2 THEN 'JOHN'     WHEN 3 THEN 'PATRICIA'
            WHEN 4 THEN 'ROBERT'   WHEN 5 THEN 'JENNIFER'
            WHEN 6 THEN 'MICHAEL'  ELSE 'LINDA'
        END                                                            AS FIRST_NAME,
        CASE MOD(rn,8)
            WHEN 0 THEN 'SMITH'    WHEN 1 THEN 'JOHNSON'
            WHEN 2 THEN 'WILLIAMS' WHEN 3 THEN 'BROWN'
            WHEN 4 THEN 'JONES'    WHEN 5 THEN 'GARCIA'
            WHEN 6 THEN 'MARTINEZ' ELSE 'DAVIS'
        END                                                            AS LAST_NAME,
        CURRENT_DATE()                                                 AS EFFECTIVE_DATE,
        NULL                                                           AS END_DATE,
        'DAILY_TASK'                                                   AS LAST_MODIFIED_BY,
        TO_VARCHAR(CURRENT_DATE(), 'YYYY-MM-DD')                      AS LAST_MODIFIED_DATE,
        (MOD(rn,3) != 0)                                              AS CONTRACT_FLAG,
        CURRENT_DATE()                                                 AS CONTRACT_EFF_DATE,
        DATEADD('year', 2, CURRENT_DATE())                            AS CONTRACT_END_DATE
    FROM (
        SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS rn
        FROM TABLE(GENERATOR(ROWCOUNT => 50))
    );

    -- -----------------------------------------------------------------------
    -- New vendor-provider links  (~100 rows, 2 links per new vendor)
    -- Links new vendors to providers that were recently added.
    -- -----------------------------------------------------------------------
    INSERT INTO PROD_RAW_DB.ORACLE.VENDOR_PROVIDER_REF (
        VENDOR_ID, PROV_REC_ID, EFFECTIVE_DATE, END_DATE,
        LAST_MODIFIED_BY, LAST_MODIFIED_DATE, VEN_PROV_KEY, DSNP
    )
    SELECT
        'VEN-' || LPAD((:max_vendor + MOD(rn - 1, :vendor_batch) + 1)::VARCHAR, 8, '0')
                                                                       AS VENDOR_ID,
        -- link to the newly inserted providers (IDs max_prov+1 through max_prov+prov_batch)
        :max_prov + MOD(rn - 1, :prov_batch) + 1                      AS PROV_REC_ID,
        CURRENT_DATE()                                                 AS EFFECTIVE_DATE,
        NULL                                                           AS END_DATE,
        'DAILY_TASK'                                                   AS LAST_MODIFIED_BY,
        TO_VARCHAR(CURRENT_DATE(), 'YYYY-MM-DD')                      AS LAST_MODIFIED_DATE,
        :max_vpref + rn                                                AS VEN_PROV_KEY,
        (MOD(rn,5) = 0)                                               AS DSNP
    FROM (
        SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS rn
        FROM TABLE(GENERATOR(ROWCOUNT => 100))
    );

    RETURN 'Inserted: ' || :prov_batch  || ' providers, ' ||
                           :vendor_batch || ' vendors, ' ||
                           :vpref_batch  || ' vendor-provider links.';
END;
$$;

-- --------------------------------------------------------------------------
-- Scheduled task: run INSERT_INCREMENTAL_DATA daily at 8am Mountain Time
-- Uses America/Denver so Snowflake adjusts automatically for MDT/MST.
-- --------------------------------------------------------------------------
CREATE OR REPLACE TASK PROD_RAW_DB.PUBLIC.DAILY_DATA_INSERT
  WAREHOUSE = DEV_ANALYTICS_WH
  SCHEDULE  = 'USING CRON 0 8 * * * America/Denver'
  COMMENT   = 'Inserts ~200 new source records daily to drive incremental dbt models'
AS
  CALL PROD_RAW_DB.PUBLIC.INSERT_INCREMENTAL_DATA();

-- Tasks start suspended by default; resume to activate.
-- NOTE: SYSADMIN requires EXECUTE TASK ON ACCOUNT and USAGE on DEV_ANALYTICS_WH.
-- Both are granted in 03_remaining_setup.sql. Run that script before this one.
ALTER TASK PROD_RAW_DB.PUBLIC.DAILY_DATA_INSERT RESUME;

-- --------------------------------------------------------------------------
-- To run immediately (manual trigger / testing):
-- --------------------------------------------------------------------------
-- EXECUTE TASK PROD_RAW_DB.PUBLIC.DAILY_DATA_INSERT;

-- --------------------------------------------------------------------------
-- To switch to every 2 hours (e.g. for demo day):
-- --------------------------------------------------------------------------
-- ALTER TASK PROD_RAW_DB.PUBLIC.DAILY_DATA_INSERT SUSPEND;
-- ALTER TASK PROD_RAW_DB.PUBLIC.DAILY_DATA_INSERT
--   SET SCHEDULE = 'USING CRON 0 */2 * * * America/Denver';
-- ALTER TASK PROD_RAW_DB.PUBLIC.DAILY_DATA_INSERT RESUME;
--
-- To revert to daily 8am MT:
-- ALTER TASK PROD_RAW_DB.PUBLIC.DAILY_DATA_INSERT SUSPEND;
-- ALTER TASK PROD_RAW_DB.PUBLIC.DAILY_DATA_INSERT
--   SET SCHEDULE = 'USING CRON 0 8 * * * America/Denver';
-- ALTER TASK PROD_RAW_DB.PUBLIC.DAILY_DATA_INSERT RESUME;
