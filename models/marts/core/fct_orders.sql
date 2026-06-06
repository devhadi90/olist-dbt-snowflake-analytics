WITH orders_enriched AS (

    SELECT * FROM {{ ref('int_orders__enriched') }}

),

customers AS (

    SELECT
        customer_id,
        customer_unique_id

    FROM {{ ref('stg_olist__customers') }}

),

final AS (

    SELECT
        -- keys
        o.order_id,
        c.customer_unique_id,
        o.customer_id,

        -- status & dates
        o.order_status,
        o.order_purchased_at,
        o.order_approved_at,
        o.order_shipped_at,
        o.order_delivered_at,
        o.order_estimated_delivery_date,

        -- measures: revenue
        o.total_order_value,
        o.payment_count,
        o.max_installments,
        o.has_credit_card_payment,

        -- measures: satisfaction
        o.review_score,

        -- measures: delivery performance
        o.actual_delivery_days,
        o.estimated_delivery_days,
        o.is_on_time_delivery,

        -- derived time dimensions (useful for BI partitioning)
        date_trunc('month', o.order_purchased_at) AS order_month,
        date_trunc('year', o.order_purchased_at) AS order_year,
        dayofweek(o.order_purchased_at) AS order_day_of_week

    FROM orders_enriched AS o
    LEFT JOIN customers AS c ON o.customer_id = c.customer_id

)

SELECT * FROM final
