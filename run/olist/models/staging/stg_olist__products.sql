
  create or replace   view olist_analytics.staging.stg_olist__products
  
  
  
  
  as (
    WITH products AS (

    SELECT * FROM olist_analytics.raw.products

),

translations AS (

    SELECT * FROM olist_analytics.raw.category_translation

),

joined AS (

    SELECT
        p.product_id,
        p.product_category_name AS product_category_portuguese,
        p.product_name_length,
        p.product_description_length,
        p.product_photos_qty,
        p.product_weight_g,
        p.product_length_cm,
        p.product_height_cm,
        p.product_width_cm,
        coalesce(t.product_category_name_english, p.product_category_name)
            AS product_category

    FROM products AS p
    LEFT JOIN translations AS t
        ON p.product_category_name = t.product_category_name

)

SELECT * FROM joined
  );

