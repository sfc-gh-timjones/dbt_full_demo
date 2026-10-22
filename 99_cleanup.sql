-- ==========================================================================
-- 99_cleanup.sql
-- Tears down everything created by scripts 01 through 05. Irreversible.
-- Order matters:
--   1. Suspend and drop tasks first (they reference procedures and warehouses)
--   2. Drop procedures explicitly (belt-and-suspenders before DB drops)
--   3. Drop dbt project + Git repo objects explicitly before analytics DB drop
--   4. Drop all databases (ACCOUNTADMIN can drop regardless of owner)
--   5. Drop warehouses
--   6. Revoke account-level privilege granted to SYSADMIN in script 03
--   7. Drop roles last (DROP ROLE auto-revokes from all users)
-- ==========================================================================

-- --------------------------------------------------------------------------
-- Tasks: dbt execution tasks (script 05)
-- Drop before analytics databases that hold the project object.
-- --------------------------------------------------------------------------
USE ROLE SYSADMIN;

ALTER TASK IF EXISTS PROD_RAW_DB.PUBLIC.DAILY_DBT_TEST SUSPEND;
DROP TASK  IF EXISTS PROD_RAW_DB.PUBLIC.DAILY_DBT_TEST;

ALTER TASK IF EXISTS PROD_RAW_DB.PUBLIC.DAILY_DBT_PROD SUSPEND;
DROP TASK  IF EXISTS PROD_RAW_DB.PUBLIC.DAILY_DBT_PROD;

-- --------------------------------------------------------------------------
-- Tasks: daily data insert + clone refresh (script 04)
-- Drop child task (DAILY_CLONE_REFRESH) before root (DAILY_DATA_INSERT).
-- --------------------------------------------------------------------------
ALTER TASK IF EXISTS PROD_RAW_DB.PUBLIC.DAILY_CLONE_REFRESH SUSPEND;
DROP TASK  IF EXISTS PROD_RAW_DB.PUBLIC.DAILY_CLONE_REFRESH;

ALTER TASK IF EXISTS PROD_RAW_DB.PUBLIC.DAILY_DATA_INSERT SUSPEND;
DROP TASK  IF EXISTS PROD_RAW_DB.PUBLIC.DAILY_DATA_INSERT;

-- --------------------------------------------------------------------------
-- Stored procedures (scripts 01 and 04)
-- Drop before their parent databases.
-- --------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS PROD_RAW_DB.PUBLIC.REFRESH_DEV_TEST_CLONES();
DROP PROCEDURE IF EXISTS PROD_RAW_DB.PUBLIC.INSERT_INCREMENTAL_DATA();
DROP PROCEDURE IF EXISTS PROD_RAW_DB.PUBLIC.SETUP_DEMO_DATA();

-- --------------------------------------------------------------------------
-- dbt project + Git repository objects (script 05)
-- Drop before DEV_ANALYTICS_DB which holds them.
-- --------------------------------------------------------------------------
DROP DBT PROJECT    IF EXISTS DEV_ANALYTICS_DB.PUBLIC.DBT_FULL_DEMO;
DROP GIT REPOSITORY IF EXISTS DEV_ANALYTICS_DB.PUBLIC.DBT_FULL_DEMO_REPO;

-- --------------------------------------------------------------------------
-- All databases (ACCOUNTADMIN — can drop regardless of owner)
-- Dropping a database cascades to all schemas, tables, views, and objects
-- inside it, including any remaining procedures or tasks.
-- --------------------------------------------------------------------------
USE ROLE ACCOUNTADMIN;

DROP DATABASE IF EXISTS DEV_ANALYTICS_DB;
DROP DATABASE IF EXISTS TEST_ANALYTICS_DB;
DROP DATABASE IF EXISTS PROD_ANALYTICS_DB;

DROP DATABASE IF EXISTS DEV_RAW_DB;
DROP DATABASE IF EXISTS TEST_RAW_DB;
DROP DATABASE IF EXISTS PROD_RAW_DB;

-- --------------------------------------------------------------------------
-- Warehouses (ACCOUNTADMIN — same role that created them)
-- --------------------------------------------------------------------------
DROP WAREHOUSE IF EXISTS DEV_ANALYTICS_WH;
DROP WAREHOUSE IF EXISTS TEST_ANALYTICS_WH;
DROP WAREHOUSE IF EXISTS PROD_ANALYTICS_WH;

-- --------------------------------------------------------------------------
-- Account-level privilege granted to SYSADMIN in script 03
-- Revoke EXECUTE TASK so SYSADMIN is back to its default privilege set.
-- --------------------------------------------------------------------------
REVOKE EXECUTE TASK ON ACCOUNT FROM ROLE SYSADMIN;

-- --------------------------------------------------------------------------
-- Roles (USERADMIN — DROP ROLE auto-revokes from all users and roles)
-- --------------------------------------------------------------------------
USE ROLE USERADMIN;

DROP ROLE IF EXISTS DEV_ANALYTICS_RL;
DROP ROLE IF EXISTS TEST_ANALYTICS_RL;
DROP ROLE IF EXISTS PROD_ANALYTICS_RL;
