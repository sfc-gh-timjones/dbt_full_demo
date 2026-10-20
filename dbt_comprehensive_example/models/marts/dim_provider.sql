-- Full provider directory: one row per provider with address, taxonomy, and NPI
with profile as (
    select * from {{ ref('int_provider_profile') }}
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
    p.line_of_business
from profile p
left join npis n on p.provider_id = n.provider_id
