WITH  __dbt__cte__int_orders__enriched as (
WITH orders AS (

    SELECT * FROM olist_analytics.staging.stg_olist__orders

),

payments AS (

    SELECT
        order_id,
        sum(payment_value) AS total_order_value,
        count(DISTINCT payment_sequential) AS payment_count,
        max(payment_installments) AS max_installments,
        -- flag if paid with credit card (most common high-value method)
        max(CASE WHEN payment_type = 'credit_card' THEN 1 ELSE 0 END)
            AS has_credit_card_payment

    FROM olist_analytics.staging.stg_olist__order_payments
    GROUP BY order_id

),

reviews AS (

    SELECT
        order_id,
        -- take the latest review if duplicates exist
        max(review_score) AS review_score,
        max(review_answered_at) AS review_answered_at

    FROM olist_analytics.staging.stg_olist__order_reviews
    GROUP BY order_id

),

enriched AS (

    SELECT
        o.order_id,
        o.customer_id,
        o.order_status,
        o.order_purchased_at,
        o.order_approved_at,
        o.order_shipped_at,
        o.order_delivered_at,
        o.order_estimated_delivery_date,

        -- payment details
        p.payment_count,
        p.max_installments,
        p.has_credit_card_payment,
        r.review_score,

        -- review details
        r.review_answered_at,
        coalesce(p.total_order_value, 0) AS total_order_value,

        -- derived
        datediff(
            'day',
            o.order_purchased_at,
            o.order_delivered_at
        ) AS actual_delivery_days,

        datediff(
            'day',
            o.order_purchased_at,
            o.order_estimated_delivery_date)
            AS estimated_delivery_days,

        coalesce(o.order_delivered_at <= o.order_estimated_delivery_date, FALSE) AS is_on_time_delivery

    FROM orders AS o
    LEFT JOIN payments AS p ON o.order_id = p.order_id
    LEFT JOIN reviews AS r ON o.order_id = r.order_id

)

SELECT * FROM enriched
), orders_enriched AS (

    SELECT * FROM __dbt__cte__int_orders__enriched

),

customers AS (

    SELECT
        customer_id,
        customer_unique_id

    FROM olist_analytics.staging.stg_olist__customers

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