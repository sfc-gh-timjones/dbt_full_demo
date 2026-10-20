with source as (
    select * from {{ source('oracle', 'vendor_provider_ref') }}
),

renamed as (
    select
        ven_prov_key                                 as vendor_provider_key,
        vendor_id,
        prov_rec_id                                  as provider_id,
        effective_date,
        end_date,
        dsnp                                         as is_dsnp,
        last_modified_by,
        try_cast(last_modified_date as date)         as last_modified_date,
        case
            when end_date is null or end_date > current_date()
            then true
            else false
        end                                          as is_active
    from source
)

select * from renamed
