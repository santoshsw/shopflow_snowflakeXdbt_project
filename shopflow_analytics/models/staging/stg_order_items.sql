
WITH source AS (
    SELECT * FROM {{ source('landing', 'raw_order_items') }}
),

renamed AS (
    SELECT
        order_item_id,
        order_id,	
        product_id,
        cast(quantity as int) AS quantity,
        cast(unit_price as decimal(12,2)) AS unit_price
    FROM source
)

SELECT * FROM renamed
