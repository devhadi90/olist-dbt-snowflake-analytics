WITH source AS (

    SELECT * FROM {{ source('olist_raw', 'order_items') }}

),

renamed AS (

    SELECT
        -- surrogate key (no single natural PK exists)
        {{ dbt_utils.generate_surrogate_key(['order_id', 'order_item_id']) }}
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
