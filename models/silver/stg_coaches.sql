{{ config(
    schema='silver',
    tags=['silver']
) }}

SELECT *
FROM {{ source('bronze', 'raw_coaches') }}
