with source as (
    select * from {{ source('oracle', 'vendor_taxonomy') }}
),

renamed as (
    select
        ven_tax_key                                  as vendor_taxonomy_key,
        vendor_id,
        taxonomy_code,
        effective_date,
        try_cast(end_date as date)                   as end_date,
        last_modified_by,
        try_cast(last_modified_date as date)         as last_modified_date,
        case
            when try_cast(end_date as date) is null
              or try_cast(end_date as date) > current_date()
            then true
            else false
        end                                          as is_active
    from source
)

select * from renamed
