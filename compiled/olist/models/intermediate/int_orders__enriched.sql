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