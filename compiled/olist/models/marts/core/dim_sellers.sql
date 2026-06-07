WITH sellers AS (

    SELECT * FROM olist_analytics.staging.stg_olist__sellers

),

geolocation AS (

    SELECT * FROM olist_analytics.staging.stg_olist__geolocation

),

joined AS (

    SELECT
        s.seller_id,
        s.zip_code_prefix,
        s.city AS seller_city,
        s.state AS seller_state,
        g.latitude AS seller_latitude,
        g.longitude AS seller_longitude

    FROM sellers AS s
    LEFT JOIN geolocation AS g ON s.zip_code_prefix = g.zip_code_prefix

)

SELECT * FROM joined