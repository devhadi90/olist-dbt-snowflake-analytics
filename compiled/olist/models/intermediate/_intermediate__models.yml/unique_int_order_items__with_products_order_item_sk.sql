
    
    

with __dbt__cte__int_order_items__with_products as (
WITH order_items AS (

    SELECT * FROM olist_analytics.staging.stg_olist__order_items

),

products AS (

    SELECT * FROM olist_analytics.staging.stg_olist__products

),

sellers AS (

    SELECT * FROM olist_analytics.staging.stg_olist__sellers

),

joined AS (

    SELECT
        oi.order_item_sk,
        oi.order_id,
        oi.order_item_id,
        oi.product_id,
        oi.seller_id,
        oi.item_price,
        oi.freight_value,
        oi.shipping_limit_at,
        p.product_category,

        -- product attributes
        p.product_weight_g,
        s.city AS seller_city,

        -- seller location
        s.state AS seller_state,
        oi.item_price + oi.freight_value AS item_total_value

    FROM order_items AS oi
    LEFT JOIN products AS p ON oi.product_id = p.product_id
    LEFT JOIN sellers AS s ON oi.seller_id = s.seller_id

)

SELECT * FROM joined
) select
    order_item_sk as unique_field,
    count(*) as n_records

from __dbt__cte__int_order_items__with_products
where order_item_sk is not null
group by order_item_sk
having count(*) > 1


