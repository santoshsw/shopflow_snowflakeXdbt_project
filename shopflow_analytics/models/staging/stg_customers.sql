SELECT 
        * 
FROM 
    {{ source('landing', 'raw_customers') }}