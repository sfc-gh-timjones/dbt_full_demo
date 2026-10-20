with source as (
    select * from {{ source('oracle', 'prv_xref1') }}
),

renamed as (
    select
        prov_rec_id                                  as provider_id,
        xref_type                                    as identifier_type,
        "REFERENCE#"                                 as identifier_value,
        state,
        lob_id                                       as line_of_business,
        eff_date                                     as effective_date,
        end_date,
        active                                       as is_active,
        try_cast(last_modified_date as date)         as last_modified_date
    from source
    where active = true
)

select * from renamed
