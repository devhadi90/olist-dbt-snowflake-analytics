WITH source AS (

    SELECT * FROM olist_analytics.raw.order_items

),

renamed AS (

    SELECT
        -- surrogate key (no single natural PK exists)
        md5(cast(coalesce(cast(order_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(order_item_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT))
            AS order_item_sk,

        -- keys
        order_id,
        order_item_id,
        product_id,
        seller_id,

        -- timestamps
        shipping_limit_date AS shipping_limit_at,

        -- amounts
        price AS item_price,
        freight_value

    FROM source

)

SELECT * FROM renamed