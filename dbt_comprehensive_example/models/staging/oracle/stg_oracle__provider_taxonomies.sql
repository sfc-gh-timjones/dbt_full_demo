with source as (
    select * from {{ source('oracle', 'prov_taxonomy') }}
),

renamed as (
    select
        prov_rec_id                                  as provider_id,
        taxonomy_code,
        primary_flag                                 as is_primary,
        eff_date                                     as effective_date,
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
