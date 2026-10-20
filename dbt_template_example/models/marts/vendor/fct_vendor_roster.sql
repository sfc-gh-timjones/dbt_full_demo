-- Vendor roster: vendors with contract status and their associated provider counts
with links as (
    select * from {{ ref('int_vendor_providers_joined') }}
),

vendors as (
    select * from {{ ref('stg_oracle__vendors') }}
),

vendor_addresses as (
    select
        vendor_id,
        address1,
        city,
        state,
        zip
    from {{ ref('stg_oracle__vendor_addresses') }}
    where is_active = true
    qualify row_number() over (partition by vendor_id order by effective_date desc) = 1
)

select
    v.vendor_id,
    v.full_name                                      as vendor_name,
    v.is_active,
    v.has_active_contract,
    v.contract_eff_date,
    v.contract_end_date,
    va.address1,
    va.city,
    va.state,
    va.zip,
    count(l.provider_id)                             as total_linked_providers,
    count(case when l.is_credentialed then 1 end)    as credentialed_provider_count,
    count(case when l.is_dsnp then 1 end)            as dsnp_provider_count,
    count(distinct l.county)                         as counties_covered
from vendors v
left join vendor_addresses va on v.vendor_id = va.vendor_id
left join links            l  on v.vendor_id = l.vendor_id
group by
    v.vendor_id,
    v.full_name,
    v.is_active,
    v.has_active_contract,
    v.contract_eff_date,
    v.contract_end_date,
    va.address1,
    va.city,
    va.state,
    va.zip
