{{ config(
    materialized = 'incremental',
    unique_key   = 'provider_id',
    post_hook    = 'ALTER TABLE {{ this }} SET CHANGE_TRACKING = TRUE'
) }}

-- Full provider directory: one row per provider with NPI, primary taxonomy,
-- address, and credentialing status.
--
-- Incremental logic: on each dbt run, only providers whose last_modified_date
-- is newer than the current max in this table are processed and upserted.
-- The CHANGE_TRACKING post-hook lets downstream dynamic tables (e.g.
-- fct_provider_county_summary) track row-level deltas off this table.

with new_providers as (
    -- Drive the incremental filter from the grain source table.
    -- On a full build (first run or --full-refresh) all rows are included.
    select
        provider_id,
        last_modified_date
    from {{ ref('stg_oracle__providers') }}
    {% if is_incremental() %}
    where last_modified_date >= (select max(last_modified_date) from {{ this }})
    {% endif %}
),

profile as (
    -- Enriched profile is a view; inner join pushes the row filter down.
    select e.*
    from {{ ref('int_providers_enriched') }} e
    inner join new_providers n on e.provider_id = n.provider_id
),

npis as (
    select
        provider_id,
        identifier_value                             as npi
    from {{ ref('stg_oracle__provider_xrefs') }}
    where identifier_type = 'NPI'
    qualify row_number() over (partition by provider_id order by effective_date desc) = 1
)

select
    p.provider_id,
    p.provider_code,
    p.provider_type,
    p.gender,
    p.date_of_birth,
    datediff('year', p.date_of_birth, current_date())  as age,
    p.primary_taxonomy_code,
    n.npi,
    p.county,
    p.area,
    p.accessible,
    p.credentialing_flag,
    p.is_credentialed,
    p.hospital_accreditation_flag,
    p.vip_flag,
    p.qasp_level,
    p.practice_street,
    p.practice_city,
    p.practice_state,
    p.practice_zip,
    p.practice_phone,
    p.line_of_business,
    np.last_modified_date                             -- watermark column; used by is_incremental() filter
from profile p
left join npis         n  on p.provider_id = n.provider_id
inner join new_providers np on p.provider_id = np.provider_id
