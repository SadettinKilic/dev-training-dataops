{{ config(materialized='view') }}

SELECT 
    n.country AS country_name,
    COUNT(DISTINCT a.code) AS athlete_count,
    COUNT(DISTINCT c.code) AS coach_count,
    COUNT(DISTINCT a.code) + COUNT(DISTINCT c.code) AS total_delegation_size,
    ROUND(COUNT(DISTINCT a.code) / NULLIF(COUNT(DISTINCT c.code), 0), 2) AS athlete_to_coach_ratio
FROM {{ ref('stg_nocs') }} n
LEFT JOIN {{ ref('stg_athletes') }} a ON n.code = a.country_code
LEFT JOIN {{ ref('stg_coaches') }} c ON n.code = c.country_code
GROUP BY 1
HAVING total_delegation_size > 0
ORDER BY total_delegation_size DESC
