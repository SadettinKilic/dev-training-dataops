{{ config(
    materialized='incremental',
    unique_key='run_id'
) }}

SELECT
  run_id,
  invocation_id,
  status,
  execution_time,
  dbt_version,
  project_name,
  target_name,
  generated_at AS run_generated_at,
  current_timestamp() AS inserted_at
FROM {{ ref('fct_dbt_run_results') }}

