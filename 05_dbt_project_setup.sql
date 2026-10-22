-- ==========================================================================
-- 05_dbt_project_setup.sql
-- Creates a Snowflake-native dbt project object from the GitHub repo
-- and daily tasks to run dbt build against the test and prod environments.
-- Run after 03_analytics_env_setup.sql.
--
-- What this script does:
--   1. Grants SYSADMIN access to the GitHub API integration and the test/prod
--      warehouses (needed to create the Git repo object and run the tasks).
--   2. Creates a Git repository object pointing to the GitHub repo.
--   3. Creates a dbt project object from the repo's dbt_template_example/ dir.
--   4. Creates two daily tasks: DAILY_DBT_TEST (test env) and DAILY_DBT_PROD
--      (prod env), both scheduled at 9am MT.
--
-- NOTE: These tasks run as SYSADMIN (EXECUTE AS OWNER). In the CI/CD phase
-- they would be replaced by pipeline jobs running as TEST_ANALYTICS_RL and
-- PROD_ANALYTICS_RL with least-privilege access.
-- ==========================================================================

-- --------------------------------------------------------------------------
-- Prerequisites: grant SYSADMIN access to integration and warehouses.
-- The GitHub API integration was created in Step 1 of the setup guide.
-- --------------------------------------------------------------------------
USE ROLE ACCOUNTADMIN;

GRANT USAGE ON INTEGRATION GIT_HUB_INTEGRATION TO ROLE SYSADMIN;
GRANT USAGE ON WAREHOUSE TEST_ANALYTICS_WH     TO ROLE SYSADMIN;
GRANT USAGE ON WAREHOUSE PROD_ANALYTICS_WH     TO ROLE SYSADMIN;

-- --------------------------------------------------------------------------
-- Git repository object
-- Snowflake fetches branches/tags from GitHub via the API integration.
-- --------------------------------------------------------------------------
USE ROLE SYSADMIN;

CREATE OR REPLACE GIT REPOSITORY DEV_ANALYTICS_DB.PUBLIC.DBT_FULL_DEMO_REPO
  API_INTEGRATION = GIT_HUB_INTEGRATION
  ORIGIN          = 'https://github.com/sfc-gh-timjones/dbt_full_demo'
  COMMENT         = 'Source repo for the dbt_full_demo project';

-- Fetch latest refs from remote
ALTER GIT REPOSITORY DEV_ANALYTICS_DB.PUBLIC.DBT_FULL_DEMO_REPO FETCH;

-- --------------------------------------------------------------------------
-- dbt project object
-- Points to the dbt_template_example/ subdirectory on the dev branch.
-- DEFAULT_ENVIRONMENT sets the env.yml block used for compilation; override
-- per execution with ENVIRONMENT = 'test' | 'prod'.
-- --------------------------------------------------------------------------
CREATE OR REPLACE DBT PROJECT DEV_ANALYTICS_DB.PUBLIC.DBT_FULL_DEMO
  FROM             '@DEV_ANALYTICS_DB.PUBLIC.DBT_FULL_DEMO_REPO/branches/dev/dbt_template_example'
  DEFAULT_ENVIRONMENT = 'prod'
  COMMENT          = 'Provider analytics dbt project — dbt_full_demo demo';

-- --------------------------------------------------------------------------
-- Daily dbt execution tasks
-- Both fire at 9am MT — after DAILY_DATA_INSERT and DAILY_CLONE_REFRESH
-- (scheduled at 8am MT) have had time to complete.
--
-- DAILY_DBT_TEST  runs dbt build against the test environment (full build).
-- DAILY_DBT_PROD  runs dbt build against the prod environment (incremental).
-- --------------------------------------------------------------------------
CREATE OR REPLACE TASK PROD_RAW_DB.PUBLIC.DAILY_DBT_TEST
  WAREHOUSE = TEST_ANALYTICS_WH
  SCHEDULE  = 'USING CRON 0 9 * * * America/Denver'
  COMMENT   = 'Runs dbt build against test environment daily at 9am MT'
AS
  EXECUTE DBT PROJECT DEV_ANALYTICS_DB.PUBLIC.DBT_FULL_DEMO
    ARGS        = 'build'
    ENVIRONMENT = 'test';

CREATE OR REPLACE TASK PROD_RAW_DB.PUBLIC.DAILY_DBT_PROD
  WAREHOUSE = PROD_ANALYTICS_WH
  SCHEDULE  = 'USING CRON 0 9 * * * America/Denver'
  COMMENT   = 'Runs dbt build against prod environment daily at 9am MT'
AS
  EXECUTE DBT PROJECT DEV_ANALYTICS_DB.PUBLIC.DBT_FULL_DEMO
    ARGS        = 'build'
    ENVIRONMENT = 'prod';

-- Tasks start suspended by default; resume to activate.
ALTER TASK PROD_RAW_DB.PUBLIC.DAILY_DBT_TEST RESUME;
ALTER TASK PROD_RAW_DB.PUBLIC.DAILY_DBT_PROD RESUME;

-- --------------------------------------------------------------------------
-- To run immediately (manual trigger / testing):
-- --------------------------------------------------------------------------
-- EXECUTE TASK PROD_RAW_DB.PUBLIC.DAILY_DBT_TEST;
-- EXECUTE TASK PROD_RAW_DB.PUBLIC.DAILY_DBT_PROD;
