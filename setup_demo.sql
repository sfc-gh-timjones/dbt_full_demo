-- ==========================================================================
-- PROD_RAW_DB Setup Script
-- Builds PROD_RAW_DB.ORACLE with all source tables and synthetic data.
--
-- Row count strategy: original counts × 5, ratios preserved across tables.
--   ORACLE.PROV              154,916  →   774,580
--   ORACLE.PROV_ADDR         193,978  →   969,890
--   ORACLE.PROV_ASSOCIATE    213,582  → 1,067,910
--   ORACLE.PROV_COMMUNICATION 38,102  →   190,510
--   ORACLE.PROV_LANGUAGE       4,666  →    23,330
--   ORACLE.PROV_TAXONOMY     152,055  →   760,275
--   ORACLE.PRV_XREF          746,647  → 3,733,235
--   ORACLE.PRV_XREF1         746,536  → 3,732,680
--   ORACLE.VENDOR             34,221  →   171,105
--   ORACLE.VENDOR_ADDRESS     38,151  →   190,755
--   ORACLE.VENDOR_PROVIDER_REF 48,772 →   243,860
--   ORACLE.VENDOR_TAXONOMY       225  →     1,125
--
-- Owner: SYSADMIN (EXECUTE AS OWNER)
-- Usage:
--   1. Run this entire script as SYSADMIN or ACCOUNTADMIN.
--   2. The final CALL statement kicks off data generation automatically.
--   Note: PRV_XREF / PRV_XREF1 are ~3.7 M rows each; allow a few minutes.
-- ==========================================================================

USE ROLE SYSADMIN;

CREATE DATABASE IF NOT EXISTS PROD_RAW_DB;
USE DATABASE PROD_RAW_DB;
CREATE SCHEMA IF NOT EXISTS ORACLE;
-- PUBLIC schema is created automatically with every new database

-- ==========================================================================
-- Stored procedure
-- ==========================================================================
CREATE OR REPLACE PROCEDURE PROD_RAW_DB.PUBLIC.SETUP_DEMO_DATA()
  RETURNS VARCHAR
  LANGUAGE SQL
  EXECUTE AS OWNER
AS
$$
BEGIN

  -- ========================================================================
  -- ORACLE.PROV  (154,916 → 774,580)
  -- ========================================================================
  CREATE OR REPLACE TABLE PROD_RAW_DB.ORACLE.PROV (
      PROV_ID                     VARCHAR,
      PROV_REC_ID                 NUMBER,
      PROV_TYPE                   VARCHAR,
      COUNTY                      VARCHAR,
      AREA                        VARCHAR,
      ACCESSIBLE                  VARCHAR,
      GENDER                      VARCHAR,
      CHANGED_DATE                VARCHAR,
      "OP#"                       NUMBER,
      LAST_MODIFIED_DATE          VARCHAR,
      LAST_MODIFIED_BY            VARCHAR,
      DOB                         DATE,
      QASP_LEVEL                  NUMBER,
      CREDENTIALING_FLAG          VARCHAR,
      HOSPITAL_ACCREDITATION_FLAG BOOLEAN,
      VIP_FLAG                    BOOLEAN
  );

  INSERT INTO PROD_RAW_DB.ORACLE.PROV
  SELECT
      'PRV-' || LPAD(rn, 8, '0')                                                        AS PROV_ID,
      rn                                                                                 AS PROV_REC_ID,
      CASE MOD(rn,5) WHEN 0 THEN 'INDIVIDUAL' WHEN 1 THEN 'ORGANIZATION'
                     WHEN 2 THEN 'FACILITY'   WHEN 3 THEN 'ANCILLARY'
                     ELSE 'GROUP' END                                                    AS PROV_TYPE,
      CASE MOD(rn,10)
          WHEN 0 THEN 'LOS ANGELES'     WHEN 1 THEN 'ORANGE'
          WHEN 2 THEN 'SAN DIEGO'       WHEN 3 THEN 'RIVERSIDE'
          WHEN 4 THEN 'SAN BERNARDINO'  WHEN 5 THEN 'VENTURA'
          WHEN 6 THEN 'SANTA BARBARA'   WHEN 7 THEN 'KERN'
          WHEN 8 THEN 'SAN LUIS OBISPO' ELSE 'IMPERIAL'
      END                                                                                AS COUNTY,
      CASE MOD(rn,4) WHEN 0 THEN 'NORTH' WHEN 1 THEN 'SOUTH'
                     WHEN 2 THEN 'EAST'  ELSE 'WEST' END                               AS AREA,
      CASE MOD(rn,2) WHEN 0 THEN 'Y' ELSE 'N' END                                     AS ACCESSIBLE,
      CASE MOD(rn,3) WHEN 0 THEN 'M' WHEN 1 THEN 'F' ELSE 'U' END                    AS GENDER,
      TO_VARCHAR(DATEADD('day', -MOD(rn,3650), DATE '2023-12-31'), 'YYYY-MM-DD')       AS CHANGED_DATE,
      MOD(rn,99) + 1                                                                    AS "OP#",
      TO_VARCHAR(DATEADD('day', -MOD(rn,365), DATE '2024-06-30'), 'YYYY-MM-DD')        AS LAST_MODIFIED_DATE,
      CASE MOD(rn,5) WHEN 0 THEN 'SYSTEM' WHEN 1 THEN 'ADMIN'
                     WHEN 2 THEN 'ETL_USER' WHEN 3 THEN 'BATCH_PROC'
                     ELSE 'DATA_LOAD' END                                               AS LAST_MODIFIED_BY,
      DATEADD('day', -(MOD(rn,18250) + 7300), CURRENT_DATE())                          AS DOB,
      MOD(rn,5) + 1                                                                     AS QASP_LEVEL,
      CASE MOD(rn,3) WHEN 0 THEN 'ACTIVE' WHEN 1 THEN 'PENDING' ELSE 'EXPIRED' END    AS CREDENTIALING_FLAG,
      (MOD(rn,4) = 0)                                                                   AS HOSPITAL_ACCREDITATION_FLAG,
      (MOD(rn,10) = 0)                                                                  AS VIP_FLAG
  FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS rn FROM TABLE(GENERATOR(ROWCOUNT => 774580)));

  -- ========================================================================
  -- ORACLE.PROV_ADDR  (193,978 → 969,890)
  -- ========================================================================
  CREATE OR REPLACE TABLE PROD_RAW_DB.ORACLE.PROV_ADDR (
      ADDR_TYPE          VARCHAR,
      LASTNAME           VARCHAR,
      FIRSTNAME          VARCHAR,
      STREET             VARCHAR,
      ADDRESS            VARCHAR,
      CITY               VARCHAR,
      STATE              VARCHAR,
      ZIP                VARCHAR,
      PHONE              VARCHAR,
      TITLE              VARCHAR,
      GREETING           VARCHAR,
      CHANGED_DATE       DATE,
      PROV_REC_ID        NUMBER,
      LOB_ID             VARCHAR,
      LAST_MODIFIED_DATE VARCHAR,
      LAST_MODIFIED_BY   VARCHAR,
      MIDDLENAME         VARCHAR,
      SUFFIX             VARCHAR,
      FTE                NUMBER,
      COUNTY             VARCHAR,
      COUNTY_CODE        NUMBER,
      AREA               VARCHAR,
      FAX                NUMBER,
      EFF_DATE           DATE,
      END_DATE           VARCHAR
  );

  INSERT INTO PROD_RAW_DB.ORACLE.PROV_ADDR
  SELECT
      CASE MOD(rn,4) WHEN 0 THEN 'PRACTICE' WHEN 1 THEN 'HOME'
                     WHEN 2 THEN 'BILLING'   ELSE 'MAILING' END                        AS ADDR_TYPE,
      CASE MOD(rn,8)
          WHEN 0 THEN 'SMITH'    WHEN 1 THEN 'JOHNSON'  WHEN 2 THEN 'WILLIAMS'
          WHEN 3 THEN 'BROWN'    WHEN 4 THEN 'JONES'    WHEN 5 THEN 'GARCIA'
          WHEN 6 THEN 'MARTINEZ' ELSE 'DAVIS'
      END                                                                               AS LASTNAME,
      CASE MOD(rn,8)
          WHEN 0 THEN 'JAMES'    WHEN 1 THEN 'MARY'      WHEN 2 THEN 'JOHN'
          WHEN 3 THEN 'PATRICIA' WHEN 4 THEN 'ROBERT'    WHEN 5 THEN 'JENNIFER'
          WHEN 6 THEN 'MICHAEL'  ELSE 'LINDA'
      END                                                                               AS FIRSTNAME,
      (MOD(rn,9999) + 1)::VARCHAR || ' ' ||
          CASE MOD(rn,5)
              WHEN 0 THEN 'MAIN ST'  WHEN 1 THEN 'OAK AVE'
              WHEN 2 THEN 'MAPLE DR' WHEN 3 THEN 'ELM BLVD'
              ELSE 'PINE RD'
          END                                                                           AS STREET,
      CASE MOD(rn,4)
          WHEN 0 THEN 'STE ' || (MOD(rn,500) + 1)::VARCHAR
          WHEN 1 THEN 'UNIT ' || (MOD(rn,200) + 1)::VARCHAR
          ELSE NULL
      END                                                                               AS ADDRESS,
      CASE MOD(rn,6)
          WHEN 0 THEN 'LOS ANGELES'   WHEN 1 THEN 'SAN DIEGO'
          WHEN 2 THEN 'SAN JOSE'      WHEN 3 THEN 'SAN FRANCISCO'
          WHEN 4 THEN 'FRESNO'        ELSE 'LONG BEACH'
      END                                                                               AS CITY,
      CASE MOD(rn,10)
          WHEN 0 THEN 'CA' WHEN 1 THEN 'NY' WHEN 2 THEN 'TX' WHEN 3 THEN 'FL'
          WHEN 4 THEN 'IL' WHEN 5 THEN 'PA' WHEN 6 THEN 'OH' WHEN 7 THEN 'GA'
          WHEN 8 THEN 'NC' ELSE 'MI'
      END                                                                               AS STATE,
      LPAD((MOD(rn,99999) + 1)::VARCHAR, 5, '0')                                      AS ZIP,
      '(' || LPAD((MOD(rn,999) + 1)::VARCHAR, 3, '0') || ') ' ||
       LPAD((MOD(rn,999) + 1)::VARCHAR, 3, '0') || '-' ||
       LPAD((MOD(rn,9000) + 1000)::VARCHAR, 4, '0')                                   AS PHONE,
      CASE MOD(rn,4) WHEN 0 THEN 'DR.' WHEN 1 THEN 'MR.'
                     WHEN 2 THEN 'MS.' ELSE 'NP' END                                  AS TITLE,
      'Dear ' || CASE MOD(rn,4) WHEN 0 THEN 'Dr.' WHEN 1 THEN 'Mr.'
                                 WHEN 2 THEN 'Ms.' ELSE 'NP' END                      AS GREETING,
      DATEADD('day', -MOD(rn,3650), DATE '2023-12-31')                                AS CHANGED_DATE,
      MOD(rn, 774580) + 1                                                              AS PROV_REC_ID,
      CASE MOD(rn,5) WHEN 0 THEN 'MEDICARE'   WHEN 1 THEN 'MEDICAID'
                     WHEN 2 THEN 'COMMERCIAL' WHEN 3 THEN 'DSNP'
                     ELSE 'CSNP' END                                                   AS LOB_ID,
      TO_VARCHAR(DATEADD('day', -MOD(rn,365), DATE '2024-06-30'), 'YYYY-MM-DD')       AS LAST_MODIFIED_DATE,
      CASE MOD(rn,5) WHEN 0 THEN 'SYSTEM' WHEN 1 THEN 'ADMIN'
                     WHEN 2 THEN 'ETL_USER' WHEN 3 THEN 'BATCH_PROC'
                     ELSE 'DATA_LOAD' END                                              AS LAST_MODIFIED_BY,
      CASE MOD(rn,4) WHEN 0 THEN 'A' WHEN 1 THEN 'B' ELSE NULL END                   AS MIDDLENAME,
      CASE MOD(rn,6) WHEN 0 THEN 'JR.' WHEN 1 THEN 'SR.' ELSE NULL END               AS SUFFIX,
      CASE MOD(rn,3) WHEN 0 THEN 1.0 WHEN 1 THEN 0.5 ELSE 0.75 END                  AS FTE,
      CASE MOD(rn,10)
          WHEN 0 THEN 'LOS ANGELES'     WHEN 1 THEN 'ORANGE'
          WHEN 2 THEN 'SAN DIEGO'       WHEN 3 THEN 'RIVERSIDE'
          WHEN 4 THEN 'SAN BERNARDINO'  WHEN 5 THEN 'VENTURA'
          WHEN 6 THEN 'SANTA BARBARA'   WHEN 7 THEN 'KERN'
          WHEN 8 THEN 'SAN LUIS OBISPO' ELSE 'IMPERIAL'
      END                                                                              AS COUNTY,
      MOD(rn,100) + 1                                                                  AS COUNTY_CODE,
      CASE MOD(rn,4) WHEN 0 THEN 'NORTH' WHEN 1 THEN 'SOUTH'
                     WHEN 2 THEN 'EAST'  ELSE 'WEST' END                              AS AREA,
      CASE MOD(rn,3) WHEN 0 THEN NULL
                     ELSE (MOD(rn,999) + 1) * 10000000
      END                                                                              AS FAX,
      DATEADD('day', MOD(rn,3650) - 3650, DATE '2020-01-01')                          AS EFF_DATE,
      CASE MOD(rn,5) WHEN 0 THEN NULL
                     ELSE TO_VARCHAR(DATEADD('day', MOD(rn,3650), DATE '2025-01-01'), 'YYYY-MM-DD')
      END                                                                              AS END_DATE
  FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS rn FROM TABLE(GENERATOR(ROWCOUNT => 969890)));

  -- ========================================================================
  -- ORACLE.PROV_ASSOCIATE  (213,582 → 1,067,910)
  -- ========================================================================
  CREATE OR REPLACE TABLE PROD_RAW_DB.ORACLE.PROV_ASSOCIATE (
      ASSOC_TYPE         VARCHAR,
      EFF_DATE           DATE,
      END_DATE           DATE,
      PROV_REC_ID        NUMBER,
      ASSOC_PROV_REC_ID  NUMBER,
      LOB_ID             VARCHAR,
      LAST_MODIFIED_DATE VARCHAR,
      LAST_MODIFIED_BY   VARCHAR
  );

  INSERT INTO PROD_RAW_DB.ORACLE.PROV_ASSOCIATE
  SELECT
      CASE MOD(rn,5)
          WHEN 0 THEN 'GROUP_MEMBER'   WHEN 1 THEN 'COVERING'
          WHEN 2 THEN 'PRACTICE_GROUP' WHEN 3 THEN 'SUPERVISING'
          ELSE 'AFFILIATED'
      END                                                                              AS ASSOC_TYPE,
      DATEADD('day', MOD(rn,3650) - 3650, DATE '2020-01-01')                         AS EFF_DATE,
      CASE MOD(rn,5) WHEN 0 THEN NULL
                     ELSE DATEADD('day', MOD(rn,3650), DATE '2025-01-01')
      END                                                                              AS END_DATE,
      MOD(rn, 774580) + 1                                                             AS PROV_REC_ID,
      MOD(rn + 387290, 774580) + 1                                                    AS ASSOC_PROV_REC_ID,
      CASE MOD(rn,5) WHEN 0 THEN 'MEDICARE'   WHEN 1 THEN 'MEDICAID'
                     WHEN 2 THEN 'COMMERCIAL' WHEN 3 THEN 'DSNP'
                     ELSE 'CSNP' END                                                  AS LOB_ID,
      TO_VARCHAR(DATEADD('day', -MOD(rn,365), DATE '2024-06-30'), 'YYYY-MM-DD')      AS LAST_MODIFIED_DATE,
      CASE MOD(rn,5) WHEN 0 THEN 'SYSTEM' WHEN 1 THEN 'ADMIN'
                     WHEN 2 THEN 'ETL_USER' WHEN 3 THEN 'BATCH_PROC'
                     ELSE 'DATA_LOAD' END                                             AS LAST_MODIFIED_BY
  FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS rn FROM TABLE(GENERATOR(ROWCOUNT => 1067910)));

  -- ========================================================================
  -- ORACLE.PROV_COMMUNICATION  (38,102 → 190,510)
  -- ========================================================================
  CREATE OR REPLACE TABLE PROD_RAW_DB.ORACLE.PROV_COMMUNICATION (
      COMM_TYPE          VARCHAR,
      COMM_SUBTYPE       VARCHAR,
      COMM_VALUE         VARCHAR,
      NOTES              VARCHAR,
      PROV_REC_ID        NUMBER,
      LOB_ID             VARCHAR,
      LAST_MODIFIED_DATE VARCHAR,
      LAST_MODIFIED_BY   VARCHAR
  );

  INSERT INTO PROD_RAW_DB.ORACLE.PROV_COMMUNICATION
  SELECT
      CASE MOD(rn,4) WHEN 0 THEN 'PHONE' WHEN 1 THEN 'FAX'
                     WHEN 2 THEN 'EMAIL' ELSE 'URL' END                               AS COMM_TYPE,
      CASE MOD(rn,3) WHEN 0 THEN 'OFFICE' WHEN 1 THEN 'AFTER_HOURS'
                     ELSE 'EMERGENCY' END                                             AS COMM_SUBTYPE,
      CASE MOD(rn,3)
          WHEN 0 THEN '(' || LPAD((MOD(rn,999)+1)::VARCHAR,3,'0') || ') ' ||
                            LPAD((MOD(rn,999)+1)::VARCHAR,3,'0') || '-' ||
                            LPAD((MOD(rn,9000)+1000)::VARCHAR,4,'0')
          WHEN 1 THEN 'provider' || rn::VARCHAR || '@healthdemo.com'
          ELSE 'https://www.provider' || rn::VARCHAR || '.com'
      END                                                                              AS COMM_VALUE,
      CASE MOD(rn,4) WHEN 0 THEN 'PRIMARY CONTACT'
                     WHEN 1 THEN 'BACKUP' ELSE NULL END                              AS NOTES,
      MOD(rn, 774580) + 1                                                             AS PROV_REC_ID,
      CASE MOD(rn,5) WHEN 0 THEN 'MEDICARE'   WHEN 1 THEN 'MEDICAID'
                     WHEN 2 THEN 'COMMERCIAL' WHEN 3 THEN 'DSNP'
                     ELSE 'CSNP' END                                                  AS LOB_ID,
      TO_VARCHAR(DATEADD('day', -MOD(rn,365), DATE '2024-06-30'), 'YYYY-MM-DD')      AS LAST_MODIFIED_DATE,
      CASE MOD(rn,5) WHEN 0 THEN 'SYSTEM' WHEN 1 THEN 'ADMIN'
                     WHEN 2 THEN 'ETL_USER' WHEN 3 THEN 'BATCH_PROC'
                     ELSE 'DATA_LOAD' END                                             AS LAST_MODIFIED_BY
  FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS rn FROM TABLE(GENERATOR(ROWCOUNT => 190510)));

  -- ========================================================================
  -- ORACLE.PROV_LANGUAGE  (4,666 → 23,330)
  -- ========================================================================
  CREATE OR REPLACE TABLE PROD_RAW_DB.ORACLE.PROV_LANGUAGE (
      PROV_LANGUAGE      VARCHAR,
      PROV_REC_ID        NUMBER,
      LAST_MODIFIED_DATE VARCHAR,
      LAST_MODIFIED_BY   VARCHAR,
      PERSONNEL          VARCHAR,
      PROFICIENCY        VARCHAR,
      EFF_DATE           DATE,
      END_DATE           DATE
  );

  INSERT INTO PROD_RAW_DB.ORACLE.PROV_LANGUAGE
  SELECT
      CASE MOD(rn,8)
          WHEN 0 THEN 'ENGLISH'    WHEN 1 THEN 'SPANISH'    WHEN 2 THEN 'CHINESE'
          WHEN 3 THEN 'TAGALOG'    WHEN 4 THEN 'VIETNAMESE' WHEN 5 THEN 'ARABIC'
          WHEN 6 THEN 'FRENCH'     ELSE 'KOREAN'
      END                                                                              AS PROV_LANGUAGE,
      MOD(rn, 774580) + 1                                                             AS PROV_REC_ID,
      TO_VARCHAR(DATEADD('day', -MOD(rn,365), DATE '2024-06-30'), 'YYYY-MM-DD')      AS LAST_MODIFIED_DATE,
      CASE MOD(rn,5) WHEN 0 THEN 'SYSTEM' WHEN 1 THEN 'ADMIN'
                     WHEN 2 THEN 'ETL_USER' WHEN 3 THEN 'BATCH_PROC'
                     ELSE 'DATA_LOAD' END                                             AS LAST_MODIFIED_BY,
      CASE MOD(rn,3) WHEN 0 THEN 'PROVIDER' WHEN 1 THEN 'STAFF'
                     ELSE 'INTERPRETER' END                                           AS PERSONNEL,
      CASE MOD(rn,4) WHEN 0 THEN 'FLUENT'    WHEN 1 THEN 'PROFICIENT'
                     WHEN 2 THEN 'BASIC'      ELSE 'NATIVE' END                      AS PROFICIENCY,
      DATEADD('day', MOD(rn,3650) - 3650, DATE '2020-01-01')                         AS EFF_DATE,
      CASE MOD(rn,5) WHEN 0 THEN NULL
                     ELSE DATEADD('day', MOD(rn,3650), DATE '2025-01-01')
      END                                                                              AS END_DATE
  FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS rn FROM TABLE(GENERATOR(ROWCOUNT => 23330)));

  -- ========================================================================
  -- ORACLE.PROV_TAXONOMY  (152,055 → 760,275)
  -- ========================================================================
  CREATE OR REPLACE TABLE PROD_RAW_DB.ORACLE.PROV_TAXONOMY (
      PROV_REC_ID        NUMBER,
      TAXONOMY_CODE      VARCHAR,
      PRIMARY_FLAG       BOOLEAN,
      EFF_DATE           DATE,
      END_DATE           DATE,
      LAST_MODIFIED_DATE VARCHAR,
      LAST_MODIFIED_BY   VARCHAR
  );

  INSERT INTO PROD_RAW_DB.ORACLE.PROV_TAXONOMY
  SELECT
      MOD(rn, 774580) + 1                                                             AS PROV_REC_ID,
      CASE MOD(rn,10)
          WHEN 0 THEN '207Q00000X' WHEN 1 THEN '208000000X' WHEN 2 THEN '207R00000X'
          WHEN 3 THEN '208100000X' WHEN 4 THEN '207V00000X' WHEN 5 THEN '207X00000X'
          WHEN 6 THEN '208G00000X' WHEN 7 THEN '207N00000X' WHEN 8 THEN '204D00000X'
          ELSE '207W00000X'
      END                                                                              AS TAXONOMY_CODE,
      (MOD(rn,3) = 0)                                                                 AS PRIMARY_FLAG,
      DATEADD('day', MOD(rn,3650) - 3650, DATE '2020-01-01')                         AS EFF_DATE,
      CASE MOD(rn,5) WHEN 0 THEN NULL
                     ELSE DATEADD('day', MOD(rn,3650), DATE '2025-01-01')
      END                                                                              AS END_DATE,
      TO_VARCHAR(DATEADD('day', -MOD(rn,365), DATE '2024-06-30'), 'YYYY-MM-DD')      AS LAST_MODIFIED_DATE,
      CASE MOD(rn,5) WHEN 0 THEN 'SYSTEM' WHEN 1 THEN 'ADMIN'
                     WHEN 2 THEN 'ETL_USER' WHEN 3 THEN 'BATCH_PROC'
                     ELSE 'DATA_LOAD' END                                             AS LAST_MODIFIED_BY
  FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS rn FROM TABLE(GENERATOR(ROWCOUNT => 760275)));

  -- ========================================================================
  -- ORACLE.PRV_XREF  (746,647 → 3,733,235)
  -- ========================================================================
  CREATE OR REPLACE TABLE PROD_RAW_DB.ORACLE.PRV_XREF (
      C1                 VARCHAR,
      PROV_REC_ID        NUMBER,
      LOB_ID             VARCHAR,
      C2                 VARCHAR,
      XREF_TYPE          VARCHAR,
      C3                 VARCHAR,
      EFF_DATE           DATE,
      C4                 VARCHAR,
      END_DATE           DATE,
      C5                 VARCHAR,
      "REFERENCE#"       VARCHAR,
      C6                 VARCHAR,
      STATE              VARCHAR,
      C7                 VARCHAR,
      C8                 VARCHAR,
      LAST_MODIFIED_DATE DATE,
      C9                 VARCHAR,
      LAST_MODIFIED_BY   VARCHAR,
      ACTIVE             VARCHAR,
      C10                VARCHAR
  );

  INSERT INTO PROD_RAW_DB.ORACLE.PRV_XREF
  SELECT
      LPAD((MOD(rn,9999) + 1)::VARCHAR, 4, '0')                                      AS C1,
      MOD(rn, 774580) + 1                                                             AS PROV_REC_ID,
      CASE MOD(rn,5) WHEN 0 THEN 'MEDICARE'   WHEN 1 THEN 'MEDICAID'
                     WHEN 2 THEN 'COMMERCIAL' WHEN 3 THEN 'DSNP'
                     ELSE 'CSNP' END                                                  AS LOB_ID,
      LPAD((MOD(rn,9999) + 1)::VARCHAR, 4, '0')                                      AS C2,
      CASE MOD(rn,6)
          WHEN 0 THEN 'NPI'        WHEN 1 THEN 'TAX_ID' WHEN 2 THEN 'DEA'
          WHEN 3 THEN 'UPIN'       WHEN 4 THEN 'MEDICAID_ID'
          ELSE 'INTERNAL'
      END                                                                              AS XREF_TYPE,
      LPAD((MOD(rn,9999) + 1)::VARCHAR, 4, '0')                                      AS C3,
      DATEADD('day', MOD(rn,3650) - 3650, DATE '2020-01-01')                         AS EFF_DATE,
      LPAD((MOD(rn,9999) + 1)::VARCHAR, 4, '0')                                      AS C4,
      CASE MOD(rn,5) WHEN 0 THEN NULL
                     ELSE DATEADD('day', MOD(rn,3650), DATE '2025-01-01')
      END                                                                              AS END_DATE,
      LPAD((MOD(rn,9999) + 1)::VARCHAR, 4, '0')                                      AS C5,
      LPAD((MOD(rn,9999999) + 1)::VARCHAR, 7, '0')                                   AS "REFERENCE#",
      LPAD((MOD(rn,9999) + 1)::VARCHAR, 4, '0')                                      AS C6,
      CASE MOD(rn,10)
          WHEN 0 THEN 'CA' WHEN 1 THEN 'NY' WHEN 2 THEN 'TX' WHEN 3 THEN 'FL'
          WHEN 4 THEN 'IL' WHEN 5 THEN 'PA' WHEN 6 THEN 'OH' WHEN 7 THEN 'GA'
          WHEN 8 THEN 'NC' ELSE 'MI'
      END                                                                              AS STATE,
      LPAD((MOD(rn,9999) + 1)::VARCHAR, 4, '0')                                      AS C7,
      LPAD((MOD(rn,9999) + 1)::VARCHAR, 4, '0')                                      AS C8,
      DATEADD('day', -MOD(rn,365), DATE '2024-06-30')                                AS LAST_MODIFIED_DATE,
      LPAD((MOD(rn,9999) + 1)::VARCHAR, 4, '0')                                      AS C9,
      CASE MOD(rn,5) WHEN 0 THEN 'SYSTEM' WHEN 1 THEN 'ADMIN'
                     WHEN 2 THEN 'ETL_USER' WHEN 3 THEN 'BATCH_PROC'
                     ELSE 'DATA_LOAD' END                                             AS LAST_MODIFIED_BY,
      CASE MOD(rn,2) WHEN 0 THEN 'Y' ELSE 'N' END                                   AS ACTIVE,
      LPAD((MOD(rn,9999) + 1)::VARCHAR, 4, '0')                                      AS C10
  FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS rn FROM TABLE(GENERATOR(ROWCOUNT => 3733235)));

  -- ========================================================================
  -- ORACLE.PRV_XREF1  (746,536 → 3,732,680)
  -- ========================================================================
  CREATE OR REPLACE TABLE PROD_RAW_DB.ORACLE.PRV_XREF1 (
      PROV_REC_ID        NUMBER,
      LOB_ID             VARCHAR,
      XREF_TYPE          VARCHAR,
      EFF_DATE           DATE,
      END_DATE           DATE,
      "REFERENCE#"       VARCHAR,
      STATE              VARCHAR,
      LAST_MODIFIED_DATE VARCHAR,
      LAST_MODIFIED_BY   VARCHAR,
      ACTIVE             BOOLEAN
  );

  INSERT INTO PROD_RAW_DB.ORACLE.PRV_XREF1
  SELECT
      MOD(rn, 774580) + 1                                                             AS PROV_REC_ID,
      CASE MOD(rn,5) WHEN 0 THEN 'MEDICARE'   WHEN 1 THEN 'MEDICAID'
                     WHEN 2 THEN 'COMMERCIAL' WHEN 3 THEN 'DSNP'
                     ELSE 'CSNP' END                                                  AS LOB_ID,
      CASE MOD(rn,6)
          WHEN 0 THEN 'NPI'        WHEN 1 THEN 'TAX_ID' WHEN 2 THEN 'DEA'
          WHEN 3 THEN 'UPIN'       WHEN 4 THEN 'MEDICAID_ID'
          ELSE 'INTERNAL'
      END                                                                              AS XREF_TYPE,
      DATEADD('day', MOD(rn,3650) - 3650, DATE '2020-01-01')                         AS EFF_DATE,
      CASE MOD(rn,5) WHEN 0 THEN NULL
                     ELSE DATEADD('day', MOD(rn,3650), DATE '2025-01-01')
      END                                                                              AS END_DATE,
      LPAD((MOD(rn,9999999) + 1)::VARCHAR, 7, '0')                                   AS "REFERENCE#",
      CASE MOD(rn,10)
          WHEN 0 THEN 'CA' WHEN 1 THEN 'NY' WHEN 2 THEN 'TX' WHEN 3 THEN 'FL'
          WHEN 4 THEN 'IL' WHEN 5 THEN 'PA' WHEN 6 THEN 'OH' WHEN 7 THEN 'GA'
          WHEN 8 THEN 'NC' ELSE 'MI'
      END                                                                              AS STATE,
      TO_VARCHAR(DATEADD('day', -MOD(rn,365), DATE '2024-06-30'), 'YYYY-MM-DD')      AS LAST_MODIFIED_DATE,
      CASE MOD(rn,5) WHEN 0 THEN 'SYSTEM' WHEN 1 THEN 'ADMIN'
                     WHEN 2 THEN 'ETL_USER' WHEN 3 THEN 'BATCH_PROC'
                     ELSE 'DATA_LOAD' END                                             AS LAST_MODIFIED_BY,
      (MOD(rn,2) = 0)                                                                 AS ACTIVE
  FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS rn FROM TABLE(GENERATOR(ROWCOUNT => 3732680)));

  -- ========================================================================
  -- ORACLE.VENDOR  (34,221 → 171,105)
  -- ========================================================================
  CREATE OR REPLACE TABLE PROD_RAW_DB.ORACLE.VENDOR (
      VENDOR_ID          VARCHAR,
      FIRST_NAME         VARCHAR,
      LAST_NAME          VARCHAR,
      EFFECTIVE_DATE     DATE,
      END_DATE           DATE,
      LAST_MODIFIED_BY   VARCHAR,
      LAST_MODIFIED_DATE VARCHAR,
      CONTRACT_FLAG      BOOLEAN,
      CONTRACT_EFF_DATE  DATE,
      CONTRACT_END_DATE  DATE
  );

  INSERT INTO PROD_RAW_DB.ORACLE.VENDOR
  SELECT
      'VEN-' || LPAD(rn, 8, '0')                                                     AS VENDOR_ID,
      CASE MOD(rn,8)
          WHEN 0 THEN 'JAMES'    WHEN 1 THEN 'MARY'      WHEN 2 THEN 'JOHN'
          WHEN 3 THEN 'PATRICIA' WHEN 4 THEN 'ROBERT'    WHEN 5 THEN 'JENNIFER'
          WHEN 6 THEN 'MICHAEL'  ELSE 'LINDA'
      END                                                                              AS FIRST_NAME,
      CASE MOD(rn,8)
          WHEN 0 THEN 'SMITH'    WHEN 1 THEN 'JOHNSON'  WHEN 2 THEN 'WILLIAMS'
          WHEN 3 THEN 'BROWN'    WHEN 4 THEN 'JONES'    WHEN 5 THEN 'GARCIA'
          WHEN 6 THEN 'MARTINEZ' ELSE 'DAVIS'
      END                                                                              AS LAST_NAME,
      DATEADD('day', MOD(rn,3650) - 3650, DATE '2020-01-01')                         AS EFFECTIVE_DATE,
      CASE MOD(rn,5) WHEN 0 THEN NULL
                     ELSE DATEADD('day', MOD(rn,3650), DATE '2025-01-01')
      END                                                                              AS END_DATE,
      CASE MOD(rn,5) WHEN 0 THEN 'SYSTEM' WHEN 1 THEN 'ADMIN'
                     WHEN 2 THEN 'ETL_USER' WHEN 3 THEN 'BATCH_PROC'
                     ELSE 'DATA_LOAD' END                                             AS LAST_MODIFIED_BY,
      TO_VARCHAR(DATEADD('day', -MOD(rn,365), DATE '2024-06-30'), 'YYYY-MM-DD')      AS LAST_MODIFIED_DATE,
      (MOD(rn,3) != 0)                                                                AS CONTRACT_FLAG,
      DATEADD('day', MOD(rn,3650) - 3650, DATE '2020-01-01')                         AS CONTRACT_EFF_DATE,
      CASE MOD(rn,5) WHEN 0 THEN NULL
                     ELSE DATEADD('day', MOD(rn,3650), DATE '2027-01-01')
      END                                                                              AS CONTRACT_END_DATE
  FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS rn FROM TABLE(GENERATOR(ROWCOUNT => 171105)));

  -- ========================================================================
  -- ORACLE.VENDOR_ADDRESS  (38,151 → 190,755)
  -- ========================================================================
  CREATE OR REPLACE TABLE PROD_RAW_DB.ORACLE.VENDOR_ADDRESS (
      REC_ID             VARCHAR,
      VENDOR_ID          VARCHAR,
      ADDRESS1           VARCHAR,
      ADDRESS2           VARCHAR,
      CITY               VARCHAR,
      STATE              VARCHAR,
      ZIP                VARCHAR,
      EFFECTIVE_DATE     DATE,
      END_DATE           DATE,
      LAST_MODIFIED_BY   VARCHAR,
      LAST_MODIFIED_DATE VARCHAR
  );

  INSERT INTO PROD_RAW_DB.ORACLE.VENDOR_ADDRESS
  SELECT
      'VA-' || LPAD(rn, 8, '0')                                                      AS REC_ID,
      'VEN-' || LPAD((MOD(rn, 171105) + 1), 8, '0')                                 AS VENDOR_ID,
      (MOD(rn,9999) + 1)::VARCHAR || ' ' ||
          CASE MOD(rn,5)
              WHEN 0 THEN 'MAIN ST'  WHEN 1 THEN 'OAK AVE'
              WHEN 2 THEN 'MAPLE DR' WHEN 3 THEN 'ELM BLVD'
              ELSE 'PINE RD'
          END                                                                          AS ADDRESS1,
      CASE MOD(rn,4) WHEN 0 THEN 'STE ' || (MOD(rn,500) + 1)::VARCHAR
                     ELSE NULL END                                                    AS ADDRESS2,
      CASE MOD(rn,6)
          WHEN 0 THEN 'LOS ANGELES' WHEN 1 THEN 'SAN DIEGO'
          WHEN 2 THEN 'SAN JOSE'    WHEN 3 THEN 'SAN FRANCISCO'
          WHEN 4 THEN 'FRESNO'      ELSE 'LONG BEACH'
      END                                                                              AS CITY,
      CASE MOD(rn,10)
          WHEN 0 THEN 'CA' WHEN 1 THEN 'NY' WHEN 2 THEN 'TX' WHEN 3 THEN 'FL'
          WHEN 4 THEN 'IL' WHEN 5 THEN 'PA' WHEN 6 THEN 'OH' WHEN 7 THEN 'GA'
          WHEN 8 THEN 'NC' ELSE 'MI'
      END                                                                              AS STATE,
      LPAD((MOD(rn,99999) + 1)::VARCHAR, 5, '0')                                     AS ZIP,
      DATEADD('day', MOD(rn,3650) - 3650, DATE '2020-01-01')                         AS EFFECTIVE_DATE,
      CASE MOD(rn,5) WHEN 0 THEN NULL
                     ELSE DATEADD('day', MOD(rn,3650), DATE '2025-01-01')
      END                                                                              AS END_DATE,
      CASE MOD(rn,5) WHEN 0 THEN 'SYSTEM' WHEN 1 THEN 'ADMIN'
                     WHEN 2 THEN 'ETL_USER' WHEN 3 THEN 'BATCH_PROC'
                     ELSE 'DATA_LOAD' END                                             AS LAST_MODIFIED_BY,
      TO_VARCHAR(DATEADD('day', -MOD(rn,365), DATE '2024-06-30'), 'YYYY-MM-DD')      AS LAST_MODIFIED_DATE
  FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS rn FROM TABLE(GENERATOR(ROWCOUNT => 190755)));

  -- ========================================================================
  -- ORACLE.VENDOR_PROVIDER_REF  (48,772 → 243,860)
  -- ========================================================================
  CREATE OR REPLACE TABLE PROD_RAW_DB.ORACLE.VENDOR_PROVIDER_REF (
      VENDOR_ID          VARCHAR,
      PROV_REC_ID        NUMBER,
      EFFECTIVE_DATE     DATE,
      END_DATE           DATE,
      LAST_MODIFIED_BY   VARCHAR,
      LAST_MODIFIED_DATE VARCHAR,
      VEN_PROV_KEY       NUMBER,
      DSNP               BOOLEAN
  );

  INSERT INTO PROD_RAW_DB.ORACLE.VENDOR_PROVIDER_REF
  SELECT
      'VEN-' || LPAD((MOD(rn, 171105) + 1), 8, '0')                                 AS VENDOR_ID,
      MOD(rn, 774580) + 1                                                             AS PROV_REC_ID,
      DATEADD('day', MOD(rn,3650) - 3650, DATE '2020-01-01')                         AS EFFECTIVE_DATE,
      CASE MOD(rn,5) WHEN 0 THEN NULL
                     ELSE DATEADD('day', MOD(rn,3650), DATE '2025-01-01')
      END                                                                              AS END_DATE,
      CASE MOD(rn,5) WHEN 0 THEN 'SYSTEM' WHEN 1 THEN 'ADMIN'
                     WHEN 2 THEN 'ETL_USER' WHEN 3 THEN 'BATCH_PROC'
                     ELSE 'DATA_LOAD' END                                             AS LAST_MODIFIED_BY,
      TO_VARCHAR(DATEADD('day', -MOD(rn,365), DATE '2024-06-30'), 'YYYY-MM-DD')      AS LAST_MODIFIED_DATE,
      rn                                                                               AS VEN_PROV_KEY,
      (MOD(rn,5) = 0)                                                                 AS DSNP
  FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS rn FROM TABLE(GENERATOR(ROWCOUNT => 243860)));

  -- ========================================================================
  -- ORACLE.VENDOR_TAXONOMY  (225 → 1,125)
  -- ========================================================================
  CREATE OR REPLACE TABLE PROD_RAW_DB.ORACLE.VENDOR_TAXONOMY (
      VENDOR_ID          VARCHAR,
      TAXONOMY_CODE      VARCHAR,
      EFFECTIVE_DATE     DATE,
      END_DATE           VARCHAR,
      LAST_MODIFIED_BY   VARCHAR,
      LAST_MODIFIED_DATE VARCHAR,
      VEN_TAX_KEY        NUMBER
  );

  INSERT INTO PROD_RAW_DB.ORACLE.VENDOR_TAXONOMY
  SELECT
      'VEN-' || LPAD((MOD(rn, 171105) + 1), 8, '0')                                 AS VENDOR_ID,
      CASE MOD(rn,10)
          WHEN 0 THEN '207Q00000X' WHEN 1 THEN '208000000X' WHEN 2 THEN '207R00000X'
          WHEN 3 THEN '208100000X' WHEN 4 THEN '207V00000X' WHEN 5 THEN '207X00000X'
          WHEN 6 THEN '208G00000X' WHEN 7 THEN '207N00000X' WHEN 8 THEN '204D00000X'
          ELSE '207W00000X'
      END                                                                              AS TAXONOMY_CODE,
      DATEADD('day', MOD(rn,3650) - 3650, DATE '2020-01-01')                         AS EFFECTIVE_DATE,
      CASE MOD(rn,5) WHEN 0 THEN NULL
                     ELSE TO_VARCHAR(DATEADD('day', MOD(rn,3650), DATE '2025-01-01'), 'YYYY-MM-DD')
      END                                                                              AS END_DATE,
      CASE MOD(rn,5) WHEN 0 THEN 'SYSTEM' WHEN 1 THEN 'ADMIN'
                     WHEN 2 THEN 'ETL_USER' WHEN 3 THEN 'BATCH_PROC'
                     ELSE 'DATA_LOAD' END                                             AS LAST_MODIFIED_BY,
      TO_VARCHAR(DATEADD('day', -MOD(rn,365), DATE '2024-06-30'), 'YYYY-MM-DD')      AS LAST_MODIFIED_DATE,
      rn                                                                               AS VEN_TAX_KEY
  FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS rn FROM TABLE(GENERATOR(ROWCOUNT => 1125)));

  RETURN 'PROD_RAW_DB setup complete. All 12 Bronze tables loaded at 5x original row counts.';
END;
$$;

-- ==========================================================================
-- Execute the setup
-- ==========================================================================
CALL PROD_RAW_DB.PUBLIC.SETUP_DEMO_DATA();
