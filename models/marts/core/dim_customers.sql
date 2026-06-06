WITH customers AS (

    SELECT * FROM {{ ref('stg_olist__customers') }}

),

orders AS (

    SELECT * FROM {{ ref('stg_olist__orders') }}

),

-- Aggregate order history per unique customer
order_history AS (

    SELECT
        c.customer_unique_id,
        count(DISTINCT o.order_id) AS total_orders,
        min(o.order_purchased_at) AS first_order_at,
        max(o.order_purchased_at) AS last_order_at,
        sum(CASE WHEN o.order_status = 'delivered' THEN 1 ELSE 0 END)
            AS delivered_orders,
        sum(CASE WHEN o.order_status = 'canceled' THEN 1 ELSE 0 END)
            AS canceled_orders

    FROM customers AS c
    LEFT JOIN orders AS o ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id

),

-- One row per unique customer, latest record wins for location
deduped_customers AS (

    SELECT DISTINCT
        customer_unique_id,
        first_value(zip_code_prefix) OVER (
            PARTITION BY customer_unique_id
            ORDER BY customer_id            -- arbitrary stable sort
        ) AS zip_code_prefix,
        first_value(city) OVER (
            PARTITION BY customer_unique_id
            ORDER BY customer_id
        ) AS customer_city,
        first_value(state) OVER (
            PARTITION BY customer_unique_id
            ORDER BY customer_id
        ) AS customer_state

    FROM customers

),

final AS (

    SELECT
        dc.customer_unique_id,
        dc.zip_code_prefix,
        dc.customer_city,
        dc.customer_state,

        oh.total_orders,
        oh.delivered_orders,
        oh.canceled_orders,
        oh.first_order_at,
        oh.last_order_at,

        datediff(
            'day',
            oh.first_order_at,
            oh.last_order_at
        ) AS customer_lifespan_days

    FROM deduped_customers AS dc
    LEFT JOIN order_history AS oh ON dc.customer_unique_id = oh.customer_unique_id

)

SELECT * FROM final
