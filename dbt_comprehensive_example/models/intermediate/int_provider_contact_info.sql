-- Provider contact info: merge phone/fax/email from address and communication tables
with providers as (
    select provider_id, provider_code, provider_type, county, area
    from {{ ref('stg_oracle__providers') }}
),

addresses as (
    select
        provider_id,
        phone                                        as address_phone,
        fax                                          as address_fax
    from {{ ref('stg_oracle__provider_addresses') }}
    where addr_type = 'PRACTICE'
      and is_active = true
    qualify row_number() over (partition by provider_id order by effective_date desc) = 1
),

communications as (
    select
        provider_id,
        max(case when communication_type = 'PHONE' and communication_subtype = 'OFFICE'
                 then communication_value end)       as office_phone,
        max(case when communication_type = 'PHONE' and communication_subtype = 'AFTER_HOURS'
                 then communication_value end)       as after_hours_phone,
        max(case when communication_type = 'EMAIL'
                 then communication_value end)       as email,
        max(case when communication_type = 'FAX'
                 then communication_value end)       as fax,
        max(case when communication_type = 'URL'
                 then communication_value end)       as website
    from {{ ref('stg_oracle__provider_communications') }}
    group by provider_id
),

languages as (
    select
        provider_id,
        listagg(language, ', ') within group (order by language) as languages_spoken
    from {{ ref('stg_oracle__provider_languages') }}
    where is_active = true
    group by provider_id
)

select
    p.provider_id,
    p.provider_code,
    p.provider_type,
    p.county,
    p.area,
    coalesce(c.office_phone, a.address_phone)        as primary_phone,
    c.after_hours_phone,
    c.fax,
    c.email,
    c.website,
    l.languages_spoken
from providers p
left join addresses      a on p.provider_id = a.provider_id
left join communications c on p.provider_id = c.provider_id
left join languages      l on p.provider_id = l.provider_id
