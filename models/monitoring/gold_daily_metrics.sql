{{ config(materialized='incremental', unique_key='table_name || run_date') }}

{% set gold_tables = [
  'dim_participants',
  'mart_country_delegation'
] %}

SELECT
  '{{ this.database }}' AS catalog_name,
  '{{ this.schema }}' AS schema_name,
  table_name,
  current_date() AS run_date,
  COUNT(*) AS row_count,
  current_timestamp() AS collected_at
FROM (
  {% for tbl in gold_tables %}
    SELECT '{{ tbl }}' AS table_name FROM {{ ref(tbl) }}
    {% if not loop.last %} UNION ALL {% endif %}
  {% endfor %}
)
GROUP BY table_name

