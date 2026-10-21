-- ==========================================================================
-- Clone PROD_RAW_DB into DEV and TEST environments
-- Run after 01_data_generation.sql
-- ==========================================================================

USE ROLE SYSADMIN;

CREATE OR REPLACE DATABASE DEV_RAW_DB  CLONE PROD_RAW_DB;
CREATE OR REPLACE DATABASE TEST_RAW_DB CLONE PROD_RAW_DB;
