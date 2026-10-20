-- Enriched provider profile: core provider + primary practice address + primary taxonomy
with providers as (
    select * from {{ ref('stg_providers') }}
),

addresses as (
    select *
    from {{ ref('stg_provider_addresses') }}
    where addr_type = 'PRACTICE'
      and is_active = true
),

taxonomies as (
    select *
    from {{ ref('stg_provider_taxonomies') }}
    where is_primary = true
      and is_active = true
),

-- One row per provider: pick the most recent practice address
ranked_addresses as (
    select *,
        row_number() over (
            partition by provider_id
            order by effective_date desc
        ) as rn
    from addresses
),

primary_address as (
    select * from ranked_addresses where rn = 1
),

-- One primary taxonomy per provider
ranked_taxonomies as (
    select *,
        row_number() over (
            partition by provider_id
            order by effective_date desc
        ) as rn
    from taxonomies
),

primary_taxonomy as (
    select * from ranked_taxonomies where rn = 1
)

select
    p.provider_id,
    p.provider_code,
    p.provider_type,
    p.gender,
    p.date_of_birth,
    p.county,
    p.area,
    p.accessible,
    p.credentialing_flag,
    p.is_credentialed,
    p.hospital_accreditation_flag,
    p.vip_flag,
    p.qasp_level,
    -- primary address
    a.street                                         as practice_street,
    a.city                                           as practice_city,
    a.state                                          as practice_state,
    a.zip                                            as practice_zip,
    a.phone                                          as practice_phone,
    a.line_of_business,
    -- primary taxonomy
    t.taxonomy_code                                  as primary_taxonomy_code
from providers p
left join primary_address a  on p.provider_id = a.provider_id
left join primary_taxonomy t on p.provider_id = t.provider_id
