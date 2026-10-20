with source as (
    select * from {{ source('oracle', 'vendor') }}
),

renamed as (
    select
        vendor_id,
        first_name,
        last_name,
        first_name || ' ' || last_name               as full_name,
        effective_date,
        end_date,
        contract_flag                                as has_contract,
        contract_eff_date,
        contract_end_date,
        try_cast(last_modified_date as date)         as last_modified_date,
        case
            when end_date is null or end_date > current_date()
            then true
            else false
        end                                          as is_active,
        case
            when contract_flag = true
              and (contract_end_date is null or contract_end_date > current_date())
            then true
            else false
        end                                          as has_active_contract
    from source
)

select * from renamed
