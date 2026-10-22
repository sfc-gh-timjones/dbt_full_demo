-- ==========================================================================
-- 05_dbt_project_setup.sql
-- Creates a Snowflake-native dbt project object from the workspace and
-- daily tasks to run dbt build against the test and prod environments.
-- Run after 04_incremental_data.sql.
--
-- What this script does:
--   1. Grants SYSADMIN access to the GitHub API integration and the test/prod
--      warehouses (needed to create the Git repo object and run the tasks).
--   2. Creates ANALYTICS_ADMIN_DB — a SYSADMIN-owned database that houses the
--      dbt project object and execution tasks. Test/prod analytics roles are
--      granted USAGE so they can execute the project.
--   3. Creates a Git repository object in DEV_ANALYTICS_DB.
--   4. Creates a dbt project object in ANALYTICS_ADMIN_DB, sourced directly
--      from the Snowflake workspace (avoids a server-side GitHub clone).
--   5. Creates two daily tasks in ANALYTICS_ADMIN_DB: DAILY_DBT_TEST and
--      DAILY_DBT_PROD, both scheduled at 9am MT.
--
-- NOTE: The workspace snow:// path uses user$ (the current user's workspace
-- namespace). The workspace must be named "dbt_full_demo" exactly as created
-- in Step 2 of the setup guide.
--
-- NOTE: Tasks run as SYSADMIN (EXECUTE AS OWNER). In the CI/CD phase they
-- would be replaced by pipeline jobs running as TEST_ANALYTICS_RL and
-- PROD_ANALYTICS_RL with least-privilege access.
-- ==========================================================================

-- --------------------------------------------------------------------------
-- Prerequisites: grant SYSADMIN access to integration and warehouses.
-- --------------------------------------------------------------------------
USE ROLE ACCOUNTADMIN;

GRANT USAGE ON INTEGRATION GIT_HUB_INTEGRATION TO ROLE SYSADMIN;
GRANT USAGE ON WAREHOUSE TEST_ANALYTICS_WH     TO ROLE SYSADMIN;
GRANT USAGE ON WAREHOUSE PROD_ANALYTICS_WH     TO ROLE SYSADMIN;

-- --------------------------------------------------------------------------
-- ANALYTICS_ADMIN_DB — shared admin database for dbt project + tasks.
-- Owned by SYSADMIN. Test/prod analytics roles get USAGE so they can
-- execute the project object from their context.
-- --------------------------------------------------------------------------
USE ROLE SYSADMIN;

CREATE DATABASE IF NOT EXISTS ANALYTICS_ADMIN_DB;

USE ROLE SECURITYADMIN;

GRANT USAGE ON DATABASE ANALYTICS_ADMIN_DB TO ROLE TEST_ANALYTICS_RL;
GRANT USAGE ON DATABASE ANALYTICS_ADMIN_DB TO ROLE PROD_ANALYTICS_RL;

-- --------------------------------------------------------------------------
-- Git repository object (in DEV_ANALYTICS_DB)
-- --------------------------------------------------------------------------
USE ROLE SYSADMIN;

CREATE OR REPLACE GIT REPOSITORY DEV_ANALYTICS_DB.PUBLIC.DBT_FULL_DEMO_REPO
  API_INTEGRATION = GIT_HUB_INTEGRATION
  ORIGIN          = 'https://github.com/sfc-gh-timjones/dbt_full_demo'
  COMMENT         = 'Source repo for the dbt_full_demo project';

ALTER GIT REPOSITORY DEV_ANALYTICS_DB.PUBLIC.DBT_FULL_DEMO_REPO FETCH;

-- --------------------------------------------------------------------------
-- dbt project object (in ANALYTICS_ADMIN_DB)
-- Sourced from the Snowflake workspace rather than a server-side GitHub
-- clone. The workspace must be named "dbt_full_demo" (created in Step 2).
-- --------------------------------------------------------------------------
CREATE OR REPLACE DBT PROJECT ANALYTICS_ADMIN_DB.PUBLIC.DBT_FULL_DEMO
  FROM             'snow://workspace/user$.public."dbt_full_demo"/versions/live/dbt_template_example'
  DEFAULT_ENVIRONMENT = 'prod'
  COMMENT          = 'Provider analytics dbt project — dbt_full_demo demo';

-- --------------------------------------------------------------------------
-- Daily dbt execution tasks (in ANALYTICS_ADMIN_DB)
-- Both fire at 9am MT — after DAILY_DATA_INSERT and DAILY_CLONE_REFRESH
-- (scheduled at 8am MT) have had time to complete.
-- --------------------------------------------------------------------------
CREATE OR REPLACE TASK ANALYTICS_ADMIN_DB.PUBLIC.DAILY_DBT_TEST
  WAREHOUSE = TEST_ANALYTICS_WH
  SCHEDULE  = 'USING CRON 0 9 * * * America/Denver'
  COMMENT   = 'Runs dbt build against test environment daily at 9am MT'
AS
  EXECUTE DBT PROJECT ANALYTICS_ADMIN_DB.PUBLIC.DBT_FULL_DEMO
    ARGS        = 'build'
    ENVIRONMENT = 'test';

CREATE OR REPLACE TASK ANALYTICS_ADMIN_DB.PUBLIC.DAILY_DBT_PROD
  WAREHOUSE = PROD_ANALYTICS_WH
  SCHEDULE  = 'USING CRON 0 9 * * * America/Denver'
  COMMENT   = 'Runs dbt build against prod environment daily at 9am MT'
AS
  EXECUTE DBT PROJECT ANALYTICS_ADMIN_DB.PUBLIC.DBT_FULL_DEMO
    ARGS        = 'build'
    ENVIRONMENT = 'prod';

-- Tasks start suspended by default; resume to activate.
ALTER TASK ANALYTICS_ADMIN_DB.PUBLIC.DAILY_DBT_TEST RESUME;
ALTER TASK ANALYTICS_ADMIN_DB.PUBLIC.DAILY_DBT_PROD RESUME;

-- --------------------------------------------------------------------------
-- To run immediately (manual trigger / testing):
-- --------------------------------------------------------------------------
-- EXECUTE TASK ANALYTICS_ADMIN_DB.PUBLIC.DAILY_DBT_TEST;
-- EXECUTE TASK ANALYTICS_ADMIN_DB.PUBLIC.DAILY_DBT_PROD;
