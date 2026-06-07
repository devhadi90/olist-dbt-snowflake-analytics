-- Raw geolocation has intentional duplicate ZIP codes (multiple points per ZIP).
-- We collapse to one row per ZIP using average coordinates.

WITH source AS (

    SELECT * FROM olist_analytics.raw.geolocation

),

deduplicated AS (

    SELECT
        geolocation_zip_code_prefix AS zip_code_prefix,
        avg(geolocation_lat) AS latitude,
        avg(geolocation_lng) AS longitude,
        -- take the most common city name per ZIP
        mode(geolocation_city) AS city,
        mode(geolocation_state) AS state

    FROM source
    GROUP BY
        geolocation_zip_code_prefix

)

SELECT * FROM deduplicated