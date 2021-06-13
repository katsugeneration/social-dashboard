{% macro range_sum_value(
        cumrate_column_name,
        rate_column_name,
        range_num,
        min_num,
        range_value_column_name
    ) %}
    {{ range_value_column_name }} * IF(
        {{ min_num }} < {{ cumrate_column_name }} - {{ rate_column_name }}
        AND {{ cumrate_column_name }} <= {{ min_num }} + {{ range_num }},
        {{ rate_column_name }},
        IF(
            {{ cumrate_column_name }} <= {{ min_num }}
            OR {{ cumrate_column_name }} - {{ rate_column_name }} > {{ min_num }} + {{ range_num }},
            0,
            IF(
                {{ cumrate_column_name }} - {{ rate_column_name }} <= {{ min_num }},
                {{ cumrate_column_name }} - {{ min_num }},
                {{ rate_column_name }} - {{ cumrate_column_name }} + {{ min_num }} + {{ range_num }}
            )
        )
    )
{% endmacro %}
