-- ==========================================================================
-- Clone PROD_RAW_DB into DEV and TEST environments
-- Run after 01_historical_data_generation.sql
--
-- Creates empty databases, then clones only the ORACLE schema from PROD.
-- PUBLIC stays empty in DEV/TEST — tasks and procedures in PROD_RAW_DB.PUBLIC
-- are never copied, so no cleanup is needed here or on re-runs.
-- ==========================================================================

USE ROLE SYSADMIN;

CREATE DATABASE IF NOT EXISTS DEV_RAW_DB;
CREATE OR REPLACE SCHEMA DEV_RAW_DB.ORACLE  CLONE PROD_RAW_DB.ORACLE;

CREATE DATABASE IF NOT EXISTS TEST_RAW_DB;
CREATE OR REPLACE SCHEMA TEST_RAW_DB.ORACLE CLONE PROD_RAW_DB.ORACLE;
