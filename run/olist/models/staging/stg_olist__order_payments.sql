
  create or replace   view olist_analytics.staging.stg_olist__order_payments
  
  
  
  
  as (
    WITH source AS (

    SELECT * FROM olist_analytics.raw.order_payments

),

renamed AS (

    SELECT
        md5(cast(coalesce(cast(order_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(payment_sequential as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT))
            AS payment_sk,

        order_id,
        payment_sequential,
        payment_type,
        payment_installments,
        payment_value

    FROM source

)

SELECT * FROM renamed
  );

