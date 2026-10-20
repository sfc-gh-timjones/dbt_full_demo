with source as (
    select * from {{ source('oracle', 'prov') }}
),

renamed as (
    select
        prov_rec_id                                  as provider_id,
        prov_id                                      as provider_code,
        prov_type                                    as provider_type,
        gender,
        dob                                          as date_of_birth,
        county,
        area,
        accessible,
        credentialing_flag,
        hospital_accreditation_flag,
        vip_flag,
        qasp_level,
        last_modified_by,
        try_cast(last_modified_date as date)         as last_modified_date,
        case
            when credentialing_flag = 'ACTIVE' then true
            else false
        end                                          as is_credentialed
    from source
)

select * from renamed
