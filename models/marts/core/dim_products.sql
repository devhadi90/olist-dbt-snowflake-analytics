WITH products AS (

    SELECT * FROM {{ ref('stg_olist__products') }}

)

SELECT
    product_id,
    product_category,
    product_category_portuguese,
    product_name_length,
    product_description_length,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm

FROM products
