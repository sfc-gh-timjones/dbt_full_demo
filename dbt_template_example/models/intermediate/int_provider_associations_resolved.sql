-- Provider network: resolve both sides of each active association with provider details
with associates as (
    select * from {{ ref('stg_oracle__provider_associates') }}
    where is_active = true
),

providers as (
    select
        provider_id,
        provider_code,
        provider_type,
        county,
        area,
        is_credentialed
    from {{ ref('stg_oracle__providers') }}
)

select
    a.provider_id,
    p1.provider_code                                 as provider_code,
    p1.provider_type                                 as provider_type,
    p1.county                                        as provider_county,
    p1.is_credentialed                               as provider_is_credentialed,
    a.association_type,
    a.associated_provider_id,
    p2.provider_code                                 as assoc_provider_code,
    p2.provider_type                                 as assoc_provider_type,
    p2.county                                        as assoc_provider_county,
    p2.is_credentialed                               as assoc_provider_is_credentialed,
    a.line_of_business,
    a.effective_date
from associates a
inner join providers p1 on a.provider_id          = p1.provider_id
inner join providers p2 on a.associated_provider_id = p2.provider_id
