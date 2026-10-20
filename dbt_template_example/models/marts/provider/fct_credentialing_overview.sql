-- Credentialing overview: provider credentialing breakdown by county, area, and type
with providers as (
    select * from {{ ref('stg_oracle__providers') }}
),

contact as (
    select
        provider_id,
        primary_phone,
        email,
        languages_spoken
    from {{ ref('int_providers_contact_pivoted') }}
)

select
    p.county,
    p.area,
    p.provider_type,
    p.credentialing_flag,
    count(*)                                                as provider_count,
    count(case when p.is_credentialed            then 1 end) as credentialed_count,
    count(case when p.hospital_accreditation_flag then 1 end) as hospital_accredited_count,
    count(case when p.vip_flag                   then 1 end) as vip_count,
    count(case when p.accessible = 'Y'           then 1 end) as accessible_count,
    avg(p.qasp_level)                                       as avg_qasp_level,
    count(case when c.email is not null          then 1 end) as providers_with_email,
    count(case when c.languages_spoken is not null then 1 end) as multilingual_providers
from providers p
left join contact c on p.provider_id = c.provider_id
group by
    p.county,
    p.area,
    p.provider_type,
    p.credentialing_flag
order by
    p.county,
    p.area,
    p.provider_type
