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
-- Scheduled tasks  (SYSADMIN — task owner)
-- Child task must be suspended before the root task and before ADMIN_DB is dropped.
-- --------------------------------------------------------------------------
USE ROLE SYSADMIN;

ALTER TASK IF EXISTS ADMIN_DB.PUBLIC.DAILY_CLONE_REFRESH SUSPEND;
DROP TASK      IF EXISTS ADMIN_DB.PUBLIC.DAILY_CLONE_REFRESH;
DROP PROCEDURE IF EXISTS ADMIN_DB.PUBLIC.REFRESH_DEV_TEST_CLONES();

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

DROP DATABASE IF EXISTS ADMIN_DB;

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
