
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select order_purchased_at
from olist_analytics.staging.stg_olist__orders
where order_purchased_at is null



  
  
      
    ) dbt_internal_test