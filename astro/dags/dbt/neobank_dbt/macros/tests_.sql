-- check unique id length
{% test check_id_length(model, column_name, id_length) %}
SELECT {{ column_name }} FROM {{ model }}
WHERE LENGTH({{ column_name }}) < {{ id_length }}
{% endtest %}

-- check for under/over-age users
{% test check_age_validity(model, column_name) %}
SELECT {{ column_name }}
FROM {{ model }}
WHERE
    ( DATEDIFF(year, {{ column_name }}, CURRENT_DATE) < 18
      OR DATEDIFF(year, {{ column_name }}, CURRENT_DATE) > 120
    )
{% endtest %}

{% test check_date_range(model, column_name) -%}
    SELECT {{ column_name }}
    FROM {{ model }}
    WHERE {{ column_name }}::date < DATE '2024-01-01'
    OR {{ column_name }}::date > CURRENT_DATE
{%- endtest %}
