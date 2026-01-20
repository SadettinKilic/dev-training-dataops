{{ config(materialized='view') }}

WITH athlete_base AS (
    SELECT 
        code AS person_id,
        name AS person_name,
        'Athlete' AS person_type,
        country_code,
        code as discipline_code,
        gender
    FROM {{ ref('stg_athletes') }}
),
coach_base AS (
    SELECT 
        code AS person_id,
        name AS person_name,
        'Coach' AS person_type,
        country_code,
        code as discipline_code,
        NULL AS gender
    FROM {{ ref('stg_coaches') }}
),
unioned AS (
    SELECT * FROM athlete_base
    UNION ALL
    SELECT * FROM coach_base
)

SELECT 
    u.*,
    n.country AS country_name
FROM unioned u
LEFT JOIN {{ ref('stg_nocs') }} n ON u.country_code = n.code
