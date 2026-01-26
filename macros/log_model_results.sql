{% macro log_model_results() %}
  {% if execute %}
    {%- set table_exists = load_relation(this) is not none -%}
    {%- if table_exists -%}
      insert into dataops.gold.audit_logs (model_name, execution_time, row_count, status)
      select 
          '{{ this.name }}', 
          current_timestamp(), 
          count(*), 
          'Success'
      from {{ this }};
    {%- endif -%}
  {% endif %}
{% endmacro %}
