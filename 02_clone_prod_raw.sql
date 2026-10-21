-- ==========================================================================
-- Clone PROD_RAW_DB into DEV and TEST environments
-- Run after 01_historical_data_generation.sql
-- ==========================================================================

USE ROLE SYSADMIN;

CREATE OR REPLACE DATABASE DEV_RAW_DB  CLONE PROD_RAW_DB;
CREATE OR REPLACE DATABASE TEST_RAW_DB CLONE PROD_RAW_DB;

-- --------------------------------------------------------------------------
-- Drop the cloned task and procedure from DEV and TEST.
-- Cloning copies all objects including the task and stored procedure, both
-- of which are hard-coded to write to PROD_RAW_DB. Resuming a clone's copy
-- would silently insert into production data. Drop them to eliminate the risk.
-- The live versions remain in PROD_RAW_DB.PUBLIC.
-- --------------------------------------------------------------------------
DROP TASK      IF EXISTS DEV_RAW_DB.PUBLIC.DAILY_DATA_INSERT;
DROP PROCEDURE IF EXISTS DEV_RAW_DB.PUBLIC.INSERT_INCREMENTAL_DATA();
DROP TASK      IF EXISTS TEST_RAW_DB.PUBLIC.DAILY_DATA_INSERT;
DROP PROCEDURE IF EXISTS TEST_RAW_DB.PUBLIC.INSERT_INCREMENTAL_DATA();
