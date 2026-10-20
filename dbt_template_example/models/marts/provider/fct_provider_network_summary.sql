-- Provider network summary: count and breakdown of each provider's active associations
with network as (
    select * from {{ ref('int_provider_associations_resolved') }}
)

select
    provider_id,
    provider_code,
    provider_type,
    provider_county,
    provider_is_credentialed,
    count(*)                                                    as total_associations,
    count(case when association_type = 'GROUP_MEMBER'   then 1 end) as group_member_count,
    count(case when association_type = 'COVERING'       then 1 end) as covering_count,
    count(case when association_type = 'PRACTICE_GROUP' then 1 end) as practice_group_count,
    count(case when association_type = 'SUPERVISING'    then 1 end) as supervising_count,
    count(case when association_type = 'AFFILIATED'     then 1 end) as affiliated_count,
    count(distinct line_of_business)                            as lob_count,
    listagg(distinct line_of_business, ', ')
        within group (order by line_of_business)                as lines_of_business
from network
group by
    provider_id,
    provider_code,
    provider_type,
    provider_county,
    provider_is_credentialed
