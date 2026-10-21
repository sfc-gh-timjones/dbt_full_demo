{{ config(
    materialized            = 'dynamic_table',
    snowflake_warehouse     = env_var('DBT_WAREHOUSE', 'DEV_ANALYTICS_WH'),
    target_lag              = '1 hour',
    refresh_mode            = 'INCREMENTAL',
    on_configuration_change = 'apply',
    pre_hook                = 'ALTER DYNAMIC TABLE IF EXISTS {{ this }} SUSPEND',
    post_hook               = 'ALTER DYNAMIC TABLE IF EXISTS {{ this }} RESUME'
) }}

-- Provider network summary aggregated by county and provider type.
-- Materialized as a Snowflake Dynamic Table with a 1-hour target lag.
--
-- In PROD: Snowflake manages refresh automatically. When the DAILY_DATA_INSERT
-- task appends rows to PROD_RAW_DB.ORACLE.PROV, the change stream detects the
-- delta and this table updates within ~1 hour — no dbt job needed.
--
-- In DEV/TEST: the DAILY_CLONE_REFRESH task replaces DEV_RAW_DB.ORACLE with a
-- fresh schema-level clone. That replacement breaks the dynamic table's change
-- stream. A plain dbt run leaves it in place (SQL unchanged). Always run
-- dbt run --full-refresh after a dev/test clone to recreate it cleanly.
--
-- What makes the PROD auto-refresh work:
--   - stg_oracle__providers is a view over the environment's ORACLE.PROV table
--   - PROV has CHANGE_TRACKING = TRUE (set in 04_incremental_data.sql)
--   - Snowflake tracks row-level deltas on PROV directly; change tracking
--     does not flow from one table through a view — PROV is the tracked object
--
-- Contrast with dim_provider (incremental): that model only refreshes when
-- dbt runs. This model refreshes on Snowflake's schedule in prod.

select
    county,
    provider_type,
    count(*)                                                    as total_providers,
    count(case when is_credentialed             then 1 end)     as credentialed_count,
    count(case when vip_flag                    then 1 end)     as vip_count,
    count(case when hospital_accreditation_flag then 1 end)     as hospital_accredited_count,
    count(case when accessible = 'Y'            then 1 end)     as accessible_count,
    max(last_modified_date)                                     as latest_modified_date
from {{ ref('stg_oracle__providers') }}
group by county, provider_type
