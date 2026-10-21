-- ==========================================================================
-- 03_remaining_setup.sql
-- Creates analytics databases, warehouses, and roles for all 3 environments
-- ==========================================================================

-- --------------------------------------------------------------------------
-- Analytics databases
-- DEV stays SYSADMIN-owned (developers write interactively).
-- TEST and PROD ownership is transferred to their role so only CI/CD can write.
-- --------------------------------------------------------------------------
USE ROLE SYSADMIN;

CREATE DATABASE IF NOT EXISTS DEV_ANALYTICS_DB;
CREATE DATABASE IF NOT EXISTS TEST_ANALYTICS_DB;
CREATE DATABASE IF NOT EXISTS PROD_ANALYTICS_DB;

USE ROLE SECURITYADMIN;
GRANT OWNERSHIP ON DATABASE TEST_ANALYTICS_DB TO ROLE TEST_ANALYTICS_RL COPY CURRENT GRANTS;
GRANT OWNERSHIP ON DATABASE PROD_ANALYTICS_DB TO ROLE PROD_ANALYTICS_RL COPY CURRENT GRANTS;

-- --------------------------------------------------------------------------
-- Warehouses  (SYSADMIN)
-- --------------------------------------------------------------------------
USE ROLE ACCOUNTADMIN; --Limit who can modify these warehouses to only highest admins.

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
-- Role grants  (SECURITYADMIN — has MANAGE GRANTS by default)
-- Each role gets USAGE + CREATE SCHEMA on its analytics DB,
-- USAGE on its warehouse, and SELECT on its raw source DB.
-- --------------------------------------------------------------------------
USE ROLE SECURITYADMIN;

-- DEV
GRANT USAGE          ON DATABASE  DEV_RAW_DB               TO ROLE DEV_ANALYTICS_RL;
GRANT USAGE          ON SCHEMA    DEV_RAW_DB.ORACLE         TO ROLE DEV_ANALYTICS_RL;
GRANT SELECT         ON ALL TABLES    IN DATABASE DEV_RAW_DB    TO ROLE DEV_ANALYTICS_RL;
GRANT SELECT         ON FUTURE TABLES IN DATABASE DEV_RAW_DB    TO ROLE DEV_ANALYTICS_RL;
GRANT USAGE          ON DATABASE  DEV_ANALYTICS_DB          TO ROLE DEV_ANALYTICS_RL;
GRANT CREATE SCHEMA  ON DATABASE  DEV_ANALYTICS_DB          TO ROLE DEV_ANALYTICS_RL;
GRANT USAGE          ON WAREHOUSE DEV_ANALYTICS_WH          TO ROLE DEV_ANALYTICS_RL;

-- TEST  (owns TEST_ANALYTICS_DB — USAGE + CREATE SCHEMA implied by ownership)
GRANT USAGE          ON DATABASE  TEST_RAW_DB               TO ROLE TEST_ANALYTICS_RL;
GRANT USAGE          ON SCHEMA    TEST_RAW_DB.ORACLE        TO ROLE TEST_ANALYTICS_RL;
GRANT SELECT         ON ALL TABLES    IN DATABASE TEST_RAW_DB   TO ROLE TEST_ANALYTICS_RL;
GRANT SELECT         ON FUTURE TABLES IN DATABASE TEST_RAW_DB   TO ROLE TEST_ANALYTICS_RL;
GRANT USAGE          ON WAREHOUSE TEST_ANALYTICS_WH         TO ROLE TEST_ANALYTICS_RL;

-- PROD  (owns PROD_ANALYTICS_DB — USAGE + CREATE SCHEMA implied by ownership)
GRANT USAGE          ON DATABASE  PROD_RAW_DB               TO ROLE PROD_ANALYTICS_RL;
GRANT USAGE          ON SCHEMA    PROD_RAW_DB.ORACLE        TO ROLE PROD_ANALYTICS_RL;
GRANT SELECT         ON ALL TABLES    IN DATABASE PROD_RAW_DB   TO ROLE PROD_ANALYTICS_RL;
GRANT SELECT         ON FUTURE TABLES IN DATABASE PROD_RAW_DB   TO ROLE PROD_ANALYTICS_RL;
GRANT USAGE          ON WAREHOUSE PROD_ANALYTICS_WH         TO ROLE PROD_ANALYTICS_RL;

-- --------------------------------------------------------------------------
-- Cross-environment read: DEV_ANALYTICS_RL can read TEST and PROD analytics.
-- Useful for comparing output across environments during development.
-- --------------------------------------------------------------------------
USE ROLE SECURITYADMIN;

GRANT USAGE  ON DATABASE TEST_ANALYTICS_DB                        TO ROLE DEV_ANALYTICS_RL;
GRANT USAGE  ON ALL SCHEMAS    IN DATABASE TEST_ANALYTICS_DB      TO ROLE DEV_ANALYTICS_RL;
GRANT USAGE  ON FUTURE SCHEMAS IN DATABASE TEST_ANALYTICS_DB      TO ROLE DEV_ANALYTICS_RL;
GRANT SELECT ON ALL TABLES     IN DATABASE TEST_ANALYTICS_DB      TO ROLE DEV_ANALYTICS_RL;
GRANT SELECT ON FUTURE TABLES  IN DATABASE TEST_ANALYTICS_DB      TO ROLE DEV_ANALYTICS_RL;
GRANT SELECT ON ALL VIEWS      IN DATABASE TEST_ANALYTICS_DB      TO ROLE DEV_ANALYTICS_RL;
GRANT SELECT ON FUTURE VIEWS   IN DATABASE TEST_ANALYTICS_DB      TO ROLE DEV_ANALYTICS_RL;

GRANT USAGE  ON DATABASE PROD_ANALYTICS_DB                        TO ROLE DEV_ANALYTICS_RL;
GRANT USAGE  ON ALL SCHEMAS    IN DATABASE PROD_ANALYTICS_DB      TO ROLE DEV_ANALYTICS_RL;
GRANT USAGE  ON FUTURE SCHEMAS IN DATABASE PROD_ANALYTICS_DB      TO ROLE DEV_ANALYTICS_RL;
GRANT SELECT ON ALL TABLES     IN DATABASE PROD_ANALYTICS_DB      TO ROLE DEV_ANALYTICS_RL;
GRANT SELECT ON FUTURE TABLES  IN DATABASE PROD_ANALYTICS_DB      TO ROLE DEV_ANALYTICS_RL;
GRANT SELECT ON ALL VIEWS      IN DATABASE PROD_ANALYTICS_DB      TO ROLE DEV_ANALYTICS_RL;
GRANT SELECT ON FUTURE VIEWS   IN DATABASE PROD_ANALYTICS_DB      TO ROLE DEV_ANALYTICS_RL;

-- --------------------------------------------------------------------------
-- Grant all three analytics roles to the current user.
-- --------------------------------------------------------------------------
USE ROLE USERADMIN;

SET current_user_name = (SELECT CURRENT_USER());

GRANT ROLE DEV_ANALYTICS_RL  TO USER IDENTIFIER($current_user_name);
GRANT ROLE TEST_ANALYTICS_RL TO USER IDENTIFIER($current_user_name);
GRANT ROLE PROD_ANALYTICS_RL TO USER IDENTIFIER($current_user_name);
