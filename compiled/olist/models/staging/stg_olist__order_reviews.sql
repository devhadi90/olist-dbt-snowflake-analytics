WITH source AS (

    SELECT * FROM olist_analytics.raw.order_reviews

),

renamed AS (

    SELECT
        review_id,
        order_id,
        review_score,
        review_creation_date AS review_created_at,
        review_answer_timestamp AS review_answered_at,
        nullif(review_comment_title, '') AS review_title,
        nullif(review_comment_message, '') AS review_message

    FROM source

)

SELECT * FROM renamed