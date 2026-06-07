
    
    

select
    zip_code_prefix as unique_field,
    count(*) as n_records

from olist_analytics.staging.stg_olist__geolocation
where zip_code_prefix is not null
group by zip_code_prefix
having count(*) > 1


