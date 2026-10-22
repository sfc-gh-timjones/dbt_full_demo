-- ==========================================================================
-- 99_cleanup.sql
-- Tears down everything created by 01, 02, and 03. Irreversible.
-- Order matters:
--   1. Drop databases first (TEST/PROD are owned by their analytics roles,
--      ACCOUNTADMIN can drop any database regardless of owner)
--   2. Drop warehouses as ACCOUNTADMIN (same role that created them)
--   3. Drop roles last (roles cannot be dropped while they own objects)
-- ==========================================================================

-- --------------------------------------------------------------------------
-- dbt project tasks and objects  (SYSADMIN — task owner)
-- Drop dbt tasks before dropping analytics databases that hold the project.
-- --------------------------------------------------------------------------
USE ROLE SYSADMIN;

ALTER TASK IF EXISTS PROD_RAW_DB.PUBLIC.DAILY_DBT_TEST SUSPEND;
DROP TASK           IF EXISTS PROD_RAW_DB.PUBLIC.DAILY_DBT_TEST;

ALTER TASK IF EXISTS PROD_RAW_DB.PUBLIC.DAILY_DBT_PROD SUSPEND;
DROP TASK           IF EXISTS PROD_RAW_DB.PUBLIC.DAILY_DBT_PROD;

-- --------------------------------------------------------------------------
-- Scheduled tasks  (SYSADMIN — task owner)
-- Both tasks live in PROD_RAW_DB.PUBLIC. Drop child before root, and both
-- before dropping PROD_RAW_DB.
-- --------------------------------------------------------------------------
USE ROLE SYSADMIN;

ALTER TASK IF EXISTS PROD_RAW_DB.PUBLIC.DAILY_CLONE_REFRESH SUSPEND;
DROP TASK      IF EXISTS PROD_RAW_DB.PUBLIC.DAILY_CLONE_REFRESH;
DROP PROCEDURE IF EXISTS PROD_RAW_DB.PUBLIC.REFRESH_DEV_TEST_CLONES();

ALTER TASK IF EXISTS PROD_RAW_DB.PUBLIC.DAILY_DATA_INSERT SUSPEND;
DROP TASK      IF EXISTS PROD_RAW_DB.PUBLIC.DAILY_DATA_INSERT;
DROP PROCEDURE IF EXISTS PROD_RAW_DB.PUBLIC.INSERT_INCREMENTAL_DATA();

-- --------------------------------------------------------------------------
-- Analytics and raw databases  (ACCOUNTADMIN — can drop regardless of owner)
-- --------------------------------------------------------------------------
USE ROLE ACCOUNTADMIN;

DROP DATABASE IF EXISTS DEV_ANALYTICS_DB;
DROP DATABASE IF EXISTS TEST_ANALYTICS_DB;
DROP DATABASE IF EXISTS PROD_ANALYTICS_DB;

DROP DATABASE IF EXISTS DEV_RAW_DB;
DROP DATABASE IF EXISTS TEST_RAW_DB;
DROP DATABASE IF EXISTS PROD_RAW_DB;

-- --------------------------------------------------------------------------
-- Warehouses  (ACCOUNTADMIN — same role that created them)
-- --------------------------------------------------------------------------
DROP WAREHOUSE IF EXISTS DEV_ANALYTICS_WH;
DROP WAREHOUSE IF EXISTS TEST_ANALYTICS_WH;
DROP WAREHOUSE IF EXISTS PROD_ANALYTICS_WH;

-- --------------------------------------------------------------------------
-- Roles  (USERADMIN)
-- DROP ROLE automatically revokes from all users before dropping.
-- --------------------------------------------------------------------------
USE ROLE USERADMIN;

DROP ROLE IF EXISTS DEV_ANALYTICS_RL;
DROP ROLE IF EXISTS TEST_ANALYTICS_RL;
DROP ROLE IF EXISTS PROD_ANALYTICS_RL;
