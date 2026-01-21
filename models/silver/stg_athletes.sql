{{ config(
    schema='silver'
) }}

SELECT *
FROM {{ source('bronze', 'raw_athletes') }}
