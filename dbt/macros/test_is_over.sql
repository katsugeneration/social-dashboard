{% macro test_is_over(
        model,
        column_name,
        criteria
    ) %}
    WITH validation AS (
        SELECT
            {{ column_name }} AS target_field
        FROM
            {{ model }}
    ),
    validation_errors AS (
        SELECT
            target_field
        FROM
            validation
        WHERE
            target_field <= {{ criteria }}
    )
SELECT
    COUNT(*)
FROM
    validation_errors
{% endmacro %}
