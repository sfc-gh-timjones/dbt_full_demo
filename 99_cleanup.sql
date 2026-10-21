-- ==========================================================================
-- 99_cleanup.sql
-- Tears down everything created by 01, 02, and 03. Irreversible.
-- ==========================================================================

-- --------------------------------------------------------------------------
-- Revoke roles from current user first  (USERADMIN)
-- --------------------------------------------------------------------------
USE ROLE USERADMIN;

SET current_user_name = (SELECT CURRENT_USER());

REVOKE ROLE DEV_ANALYTICS_RL  FROM USER IDENTIFIER($current_user_name);
REVOKE ROLE TEST_ANALYTICS_RL FROM USER IDENTIFIER($current_user_name);
REVOKE ROLE PROD_ANALYTICS_RL FROM USER IDENTIFIER($current_user_name);

DROP ROLE IF EXISTS DEV_ANALYTICS_RL;
DROP ROLE IF EXISTS TEST_ANALYTICS_RL;
DROP ROLE IF EXISTS PROD_ANALYTICS_RL;

-- --------------------------------------------------------------------------
-- Warehouses  (SYSADMIN)
-- --------------------------------------------------------------------------
USE ROLE SYSADMIN;

DROP WAREHOUSE IF EXISTS DEV_ANALYTICS_WH;
DROP WAREHOUSE IF EXISTS TEST_ANALYTICS_WH;
DROP WAREHOUSE IF EXISTS PROD_ANALYTICS_WH;

-- --------------------------------------------------------------------------
-- Analytics databases  (SYSADMIN)
-- --------------------------------------------------------------------------
DROP DATABASE IF EXISTS DEV_ANALYTICS_DB;
DROP DATABASE IF EXISTS TEST_ANALYTICS_DB;
DROP DATABASE IF EXISTS PROD_ANALYTICS_DB;

-- --------------------------------------------------------------------------
-- Raw databases  (SYSADMIN)
-- Clones first, then the source.
-- The stored procedure in PROD_RAW_DB.PUBLIC is dropped with the database.
-- --------------------------------------------------------------------------
DROP DATABASE IF EXISTS DEV_RAW_DB;
DROP DATABASE IF EXISTS TEST_RAW_DB;
DROP DATABASE IF EXISTS PROD_RAW_DB;
