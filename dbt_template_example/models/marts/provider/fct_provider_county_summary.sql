{{ config(
    materialized = 'incremental',
    unique_key   = ['county', 'provider_type']
) }}

-- Provider network summary aggregated by county and provider type.
-- Materialized as an incremental table: on each run, re-aggregates only the
-- county + provider_type groups that contain providers modified since the last run.
-- Use dbt run --full-refresh to rebuild the full table from scratch.

with providers as (
    select * from {{ ref('stg_oracle__providers') }}
)

{% if is_incremental() %}

, affected_groups as (
    select distinct county, provider_type
    from providers
    where last_modified_date >= (select max(latest_modified_date) from {{ this }})
)

select
    p.county,
    p.provider_type,
    count(*)                                                    as total_providers,
    count(case when p.is_credentialed             then 1 end)   as credentialed_count,
    count(case when p.vip_flag                    then 1 end)   as vip_count,
    count(case when p.hospital_accreditation_flag then 1 end)   as hospital_accredited_count,
    count(case when p.accessible = 'Y'            then 1 end)   as accessible_count,
    max(p.last_modified_date)                                   as latest_modified_date
from providers p
inner join affected_groups ag
    on p.county = ag.county and p.provider_type = ag.provider_type
group by p.county, p.provider_type

{% else %}

select
    county,
    provider_type,
    count(*)                                                    as total_providers,
    count(case when is_credentialed             then 1 end)     as credentialed_count,
    count(case when vip_flag                    then 1 end)     as vip_count,
    count(case when hospital_accreditation_flag then 1 end)     as hospital_accredited_count,
    count(case when accessible = 'Y'            then 1 end)     as accessible_count,
    max(last_modified_date)                                     as latest_modified_date
from providers
group by county, provider_type

{% endif %}
