-- Vendor-to-provider relationships enriched with vendor and provider details
with vendor_provider_refs as (
    select * from {{ ref('stg_vendor_provider_refs') }}
    where is_active = true
),

vendors as (
    select
        vendor_id,
        full_name                                    as vendor_name,
        has_active_contract,
        contract_eff_date,
        contract_end_date
    from {{ ref('stg_vendors') }}
),

providers as (
    select
        provider_id,
        provider_code,
        provider_type,
        county,
        area,
        is_credentialed
    from {{ ref('stg_providers') }}
)

select
    vpr.vendor_provider_key,
    vpr.vendor_id,
    v.vendor_name,
    v.has_active_contract,
    v.contract_eff_date,
    v.contract_end_date,
    vpr.provider_id,
    p.provider_code,
    p.provider_type,
    p.county,
    p.area,
    p.is_credentialed,
    vpr.is_dsnp,
    vpr.effective_date                               as relationship_start_date
from vendor_provider_refs vpr
inner join vendors   v on vpr.vendor_id   = v.vendor_id
inner join providers p on vpr.provider_id = p.provider_id
