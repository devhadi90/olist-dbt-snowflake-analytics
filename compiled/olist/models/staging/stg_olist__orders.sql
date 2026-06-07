WITH source AS (

    SELECT * FROM olist_analytics.raw.orders

),

renamed AS (

    SELECT
        -- keys
        order_id,
        customer_id,

        -- status
        order_status,

        -- timestamps (standardise column names: _at suffix for moments)
        order_purchase_timestamp AS order_purchased_at,
        order_approved_at,
        order_delivered_carrier_date AS order_shipped_at,
        order_delivered_customer_date AS order_delivered_at,
        order_estimated_delivery_date

    FROM source

)

SELECT * FROM renamed