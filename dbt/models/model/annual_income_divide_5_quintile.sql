{{ config(
    materialized = 'view'
) }}

SELECT
    CONCAT(
        "大学: ",
        university_type
    ) AS TYPE,
    YEAR,
    quintile,
    VALUE * 10000 AS VALUE
FROM
    social_dataset.jasso_gakuseiseikatsu_stats_annual_income_divide_university_type_and_income
UNION ALL
SELECT
    houseshold_type AS TYPE,
    YEAR,
    quintile,
    VALUE * 10 AS VALUE
FROM
    social_dataset.ja_kakei_chousa_income_divide_over_two_member
WHERE
    acquisition_year = 2020
    AND aggregation_type = '実収入'
