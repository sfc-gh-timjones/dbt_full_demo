with source as (
    select * from {{ source('oracle', 'prov_language') }}
),

renamed as (
    select
        prov_rec_id                                  as provider_id,
        prov_language                                as language,
        personnel,
        proficiency,
        eff_date                                     as effective_date,
        end_date,
        case
            when end_date is null or end_date > current_date()
            then true
            else false
        end                                          as is_active
    from source
)

select * from renamed
