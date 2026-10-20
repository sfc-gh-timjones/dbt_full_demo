with source as (
    select * from {{ source('oracle', 'prov_communication') }}
),

renamed as (
    select
        prov_rec_id                                  as provider_id,
        comm_type                                    as communication_type,
        comm_subtype                                 as communication_subtype,
        comm_value                                   as communication_value,
        notes,
        lob_id                                       as line_of_business,
        last_modified_by,
        try_cast(last_modified_date as date)         as last_modified_date
    from source
)

select * from renamed
