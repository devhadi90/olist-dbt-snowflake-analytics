WITH source AS (

    SELECT * FROM {{ source('olist_raw', 'order_payments') }}

),

renamed AS (

    SELECT
        {{ dbt_utils.generate_surrogate_key(['order_id', 'payment_sequential']) }}
            AS payment_sk,

        order_id,
        payment_sequential,
        payment_type,
        payment_installments,
        payment_value

    FROM source

)

SELECT * FROM renamed
