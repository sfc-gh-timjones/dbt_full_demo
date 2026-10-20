with source as (
    select * from {{ source('oracle', 'vendor_address') }}
),

renamed as (
    select
        rec_id,
        vendor_id,
        address1,
        address2,
        city,
        state,
        zip,
        effective_date,
        end_date,
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
