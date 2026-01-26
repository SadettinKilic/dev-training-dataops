{% macro log_model_results() %}
  {% if execute %}
    insert into dataops.bronze.audit_logs (model_name, execution_time, row_count, status)
    values ('{{ this.name }}', current_timestamp(), (select count(*) from {{ this }}), 'Success');
  {% endif %}
{% endmacro %}
