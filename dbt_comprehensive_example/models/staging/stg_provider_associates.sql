with source as (
    select * from {{ source('oracle', 'prov_associate') }}
),

renamed as (
    select
        prov_rec_id                                  as provider_id,
        assoc_prov_rec_id                            as associated_provider_id,
        assoc_type                                   as association_type,
        lob_id                                       as line_of_business,
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
