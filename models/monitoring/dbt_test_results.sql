{{ config(
    materialized='incremental',
    unique_key='test_execution_id'
) }}

SELECT
  test_execution_id,
  invocation_id,
  status,
  failures,
  test_name,
  model_name,
  generated_at,
  current_timestamp() AS inserted_at
FROM {{ ref('fct_dbt_test_results') }}

