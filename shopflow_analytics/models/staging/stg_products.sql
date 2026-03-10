
WITH source AS (
    SELECT * FROM {{ source('landing', 'raw_products') }}
    
),

renamed AS (
    SELECT
        product_id,
        trim(product_name) AS product_name,
        trim(category) AS category,
        cast(price as decimal(12,2)) AS price
    FROM source
)

SELECT * FROM renamed
