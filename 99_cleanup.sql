-- ==========================================================================
-- 99_cleanup.sql
-- Tears down everything created by scripts 01 through 05. Irreversible.
-- Order matters:
--   1. Suspend and drop tasks first (SYSADMIN — owns all tasks)
--   2. Drop procedures explicitly (SYSADMIN — owns all raw DB objects)
--   3. Drop databases as their owning role (dbt project + Git repo cascade):
--        SYSADMIN          → DEV_ANALYTICS_DB, DEV/TEST/PROD_RAW_DB
--        TEST_ANALYTICS_RL → TEST_ANALYTICS_DB  (ownership transferred in 03)
--        PROD_ANALYTICS_RL → PROD_ANALYTICS_DB  (ownership transferred in 03)
--   5. Drop warehouses (ACCOUNTADMIN — created them)
--   6. Revoke account-level privilege granted to SYSADMIN in script 03
--   7. Drop roles last (DROP ROLE auto-revokes from all users)
-- ==========================================================================

-- --------------------------------------------------------------------------
-- Tasks: dbt execution tasks (script 05)
-- Owned by SYSADMIN. Drop before analytics databases that hold the project.
-- --------------------------------------------------------------------------
USE ROLE SYSADMIN;

ALTER TASK IF EXISTS PROD_RAW_DB.PUBLIC.DAILY_DBT_TEST SUSPEND;
DROP TASK  IF EXISTS PROD_RAW_DB.PUBLIC.DAILY_DBT_TEST;

ALTER TASK IF EXISTS PROD_RAW_DB.PUBLIC.DAILY_DBT_PROD SUSPEND;
DROP TASK  IF EXISTS PROD_RAW_DB.PUBLIC.DAILY_DBT_PROD;

-- --------------------------------------------------------------------------
-- Tasks: daily data insert + clone refresh (script 04)
-- Owned by SYSADMIN. Suspend root first (required before modifying any child
-- in the graph), then suspend + drop child, then drop root.
-- --------------------------------------------------------------------------
ALTER TASK IF EXISTS PROD_RAW_DB.PUBLIC.DAILY_DATA_INSERT SUSPEND;

ALTER TASK IF EXISTS PROD_RAW_DB.PUBLIC.DAILY_CLONE_REFRESH SUSPEND;
DROP TASK  IF EXISTS PROD_RAW_DB.PUBLIC.DAILY_CLONE_REFRESH;

DROP TASK  IF EXISTS PROD_RAW_DB.PUBLIC.DAILY_DATA_INSERT;

-- --------------------------------------------------------------------------
-- Stored procedures (scripts 01 and 04)
-- Owned by SYSADMIN. Drop before their parent databases.
-- --------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS PROD_RAW_DB.PUBLIC.REFRESH_DEV_TEST_CLONES();
DROP PROCEDURE IF EXISTS PROD_RAW_DB.PUBLIC.INSERT_INCREMENTAL_DATA();
DROP PROCEDURE IF EXISTS PROD_RAW_DB.PUBLIC.SETUP_DEMO_DATA();

-- --------------------------------------------------------------------------
-- DEV_ANALYTICS_DB and all raw databases — owned by SYSADMIN
-- Dropping the database cascades to all objects inside it, including the
-- DBT_FULL_DEMO dbt project and DBT_FULL_DEMO_REPO git repository (script 05).
-- --------------------------------------------------------------------------
DROP DATABASE IF EXISTS DEV_ANALYTICS_DB;
DROP DATABASE IF EXISTS DEV_RAW_DB;
DROP DATABASE IF EXISTS TEST_RAW_DB;
DROP DATABASE IF EXISTS PROD_RAW_DB;

-- --------------------------------------------------------------------------
-- TEST_ANALYTICS_DB — ownership transferred to TEST_ANALYTICS_RL in script 03
-- --------------------------------------------------------------------------
USE ROLE TEST_ANALYTICS_RL;
DROP DATABASE IF EXISTS TEST_ANALYTICS_DB;

-- --------------------------------------------------------------------------
-- PROD_ANALYTICS_DB — ownership transferred to PROD_ANALYTICS_RL in script 03
-- --------------------------------------------------------------------------
USE ROLE PROD_ANALYTICS_RL;
DROP DATABASE IF EXISTS PROD_ANALYTICS_DB;

-- --------------------------------------------------------------------------
-- Warehouses — created by ACCOUNTADMIN
-- --------------------------------------------------------------------------
USE ROLE ACCOUNTADMIN;
DROP WAREHOUSE IF EXISTS DEV_ANALYTICS_WH;
DROP WAREHOUSE IF EXISTS TEST_ANALYTICS_WH;
DROP WAREHOUSE IF EXISTS PROD_ANALYTICS_WH;

-- --------------------------------------------------------------------------
-- Account-level privilege granted to SYSADMIN in script 03
-- --------------------------------------------------------------------------
REVOKE EXECUTE TASK ON ACCOUNT FROM ROLE SYSADMIN;

-- --------------------------------------------------------------------------
-- Roles (USERADMIN — DROP ROLE auto-revokes from all users and roles)
-- --------------------------------------------------------------------------
USE ROLE USERADMIN;
DROP ROLE IF EXISTS DEV_ANALYTICS_RL;
DROP ROLE IF EXISTS TEST_ANALYTICS_RL;
DROP ROLE IF EXISTS PROD_ANALYTICS_RL;
