WITH source AS (

    SELECT * 
    FROM {{ source('landing', 'raw_orders') }}

),

renamed AS (

    SELECT
        order_id,
        customer_id,
        CAST(order_date AS DATE) AS order_date,
        LOWER(TRIM(status)) AS status,
        CAST(total_amount AS DECIMAL(12,2)) AS total_amount

    FROM source

)

SELECT * FROM renamed