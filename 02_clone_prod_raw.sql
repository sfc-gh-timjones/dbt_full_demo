-- ==========================================================================
-- Clone PROD_RAW_DB into DEV and TEST environments
-- Run after 01_historical_data_generation.sql
-- ==========================================================================

USE ROLE SYSADMIN;

CREATE OR REPLACE DATABASE DEV_RAW_DB  CLONE PROD_RAW_DB;
CREATE OR REPLACE DATABASE TEST_RAW_DB CLONE PROD_RAW_DB;

-- --------------------------------------------------------------------------
-- Drop the cloned tasks and procedures from DEV and TEST.
-- On initial setup (02 runs before 04), these objects don't exist yet and
-- the drops are no-ops. If someone re-runs 02 after 04 has already populated
-- PROD_RAW_DB.PUBLIC, all four objects will be present in the clones and must
-- be dropped — they all write to or re-clone PROD_RAW_DB.
-- The live versions remain in PROD_RAW_DB.PUBLIC.
-- --------------------------------------------------------------------------
DROP TASK      IF EXISTS DEV_RAW_DB.PUBLIC.DAILY_DATA_INSERT;
DROP TASK      IF EXISTS DEV_RAW_DB.PUBLIC.DAILY_CLONE_REFRESH;
DROP PROCEDURE IF EXISTS DEV_RAW_DB.PUBLIC.INSERT_INCREMENTAL_DATA();
DROP PROCEDURE IF EXISTS DEV_RAW_DB.PUBLIC.REFRESH_DEV_TEST_CLONES();
DROP TASK      IF EXISTS TEST_RAW_DB.PUBLIC.DAILY_DATA_INSERT;
DROP TASK      IF EXISTS TEST_RAW_DB.PUBLIC.DAILY_CLONE_REFRESH;
DROP PROCEDURE IF EXISTS TEST_RAW_DB.PUBLIC.INSERT_INCREMENTAL_DATA();
DROP PROCEDURE IF EXISTS TEST_RAW_DB.PUBLIC.REFRESH_DEV_TEST_CLONES();
