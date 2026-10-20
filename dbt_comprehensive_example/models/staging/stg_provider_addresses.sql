with source as (
    select * from {{ source('oracle', 'prov_addr') }}
),

renamed as (
    select
        prov_rec_id                                  as provider_id,
        addr_type,
        lastname                                     as last_name,
        firstname                                    as first_name,
        middlename                                   as middle_name,
        suffix,
        title,
        street,
        address                                      as address_line2,
        city,
        state,
        zip,
        county,
        county_code,
        area,
        phone,
        fax,
        fte,
        lob_id                                       as line_of_business,
        eff_date                                     as effective_date,
        try_cast(end_date as date)                   as end_date,
        case
            when try_cast(end_date as date) is null
              or try_cast(end_date as date) > current_date()
            then true
            else false
        end                                          as is_active
    from source
)

select * from renamed
