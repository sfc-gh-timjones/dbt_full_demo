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
