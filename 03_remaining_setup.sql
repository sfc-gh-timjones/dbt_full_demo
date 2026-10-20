-- ==========================================================================
-- 03_remaining_setup.sql
-- Creates analytics databases, warehouses, and roles for all 3 environments
-- ==========================================================================

-- --------------------------------------------------------------------------
-- Analytics databases  (SYSADMIN)
-- --------------------------------------------------------------------------
USE ROLE SYSADMIN;

CREATE DATABASE IF NOT EXISTS DEV_ANALYTICS_DB;
CREATE DATABASE IF NOT EXISTS TEST_ANALYTICS_DB;
CREATE DATABASE IF NOT EXISTS PROD_ANALYTICS_DB;

-- --------------------------------------------------------------------------
-- Warehouses  (SYSADMIN)
-- --------------------------------------------------------------------------
CREATE WAREHOUSE IF NOT EXISTS DEV_ANALYTICS_WH
    WAREHOUSE_SIZE   = XSMALL
    AUTO_SUSPEND     = 30
    AUTO_RESUME      = TRUE
    INITIALLY_SUSPENDED = TRUE;

CREATE WAREHOUSE IF NOT EXISTS TEST_ANALYTICS_WH
    WAREHOUSE_SIZE   = XSMALL
    AUTO_SUSPEND     = 30
    AUTO_RESUME      = TRUE
    INITIALLY_SUSPENDED = TRUE;

CREATE WAREHOUSE IF NOT EXISTS PROD_ANALYTICS_WH
    WAREHOUSE_SIZE   = XSMALL
    AUTO_SUSPEND     = 30
    AUTO_RESUME      = TRUE
    INITIALLY_SUSPENDED = TRUE;

-- --------------------------------------------------------------------------
-- Roles  (USERADMIN)
-- --------------------------------------------------------------------------
USE ROLE USERADMIN;

CREATE ROLE IF NOT EXISTS DEV_ANALYTICS_RL;
CREATE ROLE IF NOT EXISTS TEST_ANALYTICS_RL;
CREATE ROLE IF NOT EXISTS PROD_ANALYTICS_RL;

-- --------------------------------------------------------------------------
-- Role grants  (SYSADMIN)
-- Each role gets USAGE + CREATE SCHEMA on its analytics DB,
-- and USAGE + OPERATE on its warehouse so dbt can create schemas and run.
-- --------------------------------------------------------------------------
USE ROLE SYSADMIN;

-- DEV
GRANT USAGE         ON DATABASE DEV_ANALYTICS_DB  TO ROLE DEV_ANALYTICS_RL;
GRANT CREATE SCHEMA ON DATABASE DEV_ANALYTICS_DB  TO ROLE DEV_ANALYTICS_RL;
GRANT USAGE         ON WAREHOUSE DEV_ANALYTICS_WH TO ROLE DEV_ANALYTICS_RL;
GRANT OPERATE       ON WAREHOUSE DEV_ANALYTICS_WH TO ROLE DEV_ANALYTICS_RL;

-- TEST
GRANT USAGE         ON DATABASE TEST_ANALYTICS_DB  TO ROLE TEST_ANALYTICS_RL;
GRANT CREATE SCHEMA ON DATABASE TEST_ANALYTICS_DB  TO ROLE TEST_ANALYTICS_RL;
GRANT USAGE         ON WAREHOUSE TEST_ANALYTICS_WH TO ROLE TEST_ANALYTICS_RL;
GRANT OPERATE       ON WAREHOUSE TEST_ANALYTICS_WH TO ROLE TEST_ANALYTICS_RL;

-- PROD
GRANT USAGE         ON DATABASE PROD_ANALYTICS_DB  TO ROLE PROD_ANALYTICS_RL;
GRANT CREATE SCHEMA ON DATABASE PROD_ANALYTICS_DB  TO ROLE PROD_ANALYTICS_RL;
GRANT USAGE         ON WAREHOUSE PROD_ANALYTICS_WH TO ROLE PROD_ANALYTICS_RL;
GRANT OPERATE       ON WAREHOUSE PROD_ANALYTICS_WH TO ROLE PROD_ANALYTICS_RL;
