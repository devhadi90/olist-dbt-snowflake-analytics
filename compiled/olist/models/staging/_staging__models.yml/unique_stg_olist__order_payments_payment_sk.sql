
    
    

select
    payment_sk as unique_field,
    count(*) as n_records

from olist_analytics.staging.stg_olist__order_payments
where payment_sk is not null
group by payment_sk
having count(*) > 1


