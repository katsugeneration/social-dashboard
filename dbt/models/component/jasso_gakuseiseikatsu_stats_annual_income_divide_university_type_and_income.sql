{{ config(
    materialized = 'view'
) }}

WITH temp_incomes AS (

    SELECT
        university_type,
        YEAR,
        CASE
            `range`
            WHEN '200万円未満' THEN 150
            ELSE CAST(
                REPLACE(regexp_extract(`range`, "[0-9,]*"), ',', '') AS int64
            ) + 50
        END AS range_value,
        `range`,
        rate
    FROM
        social_dataset.jasso_gakuseiseikatsu_stats_annual_income_divide_university
    WHERE
        sex = '平均'
),
cum_rates AS (
    SELECT
        university_type,
        YEAR,
        `range`,
        range_value,
        rate,
        SUM(rate) over (
            PARTITION BY university_type,
            YEAR
            ORDER BY
                range_value
        ) AS cumrate
    FROM
        temp_incomes
    ORDER BY
        university_type,
        range_value
),
divide_1st AS (
    SELECT
        university_type,
        YEAR,
        SUM(
            range_value * IF(
                cumrate <= 20,
                rate,
                IF(
                    cumrate - rate > 20,
                    0,
                    rate - cumrate + 20
                )
            )
        ) / 20 AS avg_income
    FROM
        cum_rates
    GROUP BY
        university_type,
        YEAR
),
divide_2nd AS (
    SELECT
        university_type,
        YEAR,
        SUM(
            range_value * IF(
                20 < cumrate - rate
                AND cumrate <= 40,
                rate,
                IF(
                    cumrate <= 20
                    OR cumrate - rate > 40,
                    0,
                    IF(
                        cumrate - rate <= 20,
                        cumrate - 20,
                        rate - cumrate + 40
                    )
                )
            )
        ) / 20 AS avg_income
    FROM
        cum_rates
    GROUP BY
        university_type,
        YEAR
),
divide_3rd AS (
    SELECT
        university_type,
        YEAR,
        SUM(
            range_value * IF(
                40 < cumrate - rate
                AND cumrate <= 60,
                rate,
                IF(
                    cumrate <= 40
                    OR cumrate - rate > 60,
                    0,
                    IF(
                        cumrate - rate <= 40,
                        cumrate - 40,
                        rate - cumrate + 60
                    )
                )
            )
        ) / 20 AS avg_income
    FROM
        cum_rates
    GROUP BY
        university_type,
        YEAR
),
divide_4th AS (
    SELECT
        university_type,
        YEAR,
        SUM(
            range_value * IF(
                60 < cumrate - rate
                AND cumrate <= 80,
                rate,
                IF(
                    cumrate <= 60
                    OR cumrate - rate > 80,
                    0,
                    IF(
                        cumrate - rate <= 60,
                        cumrate - 60,
                        rate - cumrate + 80
                    )
                )
            )
        ) / 20 AS avg_income
    FROM
        cum_rates
    GROUP BY
        university_type,
        YEAR
),
divide_5th AS (
    SELECT
        university_type,
        YEAR,
        SUM(
            range_value * IF(
                80 < cumrate - rate,
                rate,
                IF(
                    cumrate > 80
                    AND cumrate - rate <= 80,
                    cumrate - 80,
                    0
                )
            )
        ) / 20 AS avg_income
    FROM
        cum_rates
    GROUP BY
        university_type,
        YEAR
)
SELECT
    divide_1st.university_type,
    divide_1st.year,
    divide_1st.avg_income AS divide_1st,
    divide_2nd.avg_income AS divide_2nd,
    divide_3rd.avg_income AS divide_3rd,
    divide_4th.avg_income AS divide_4th,
    divide_5th.avg_income AS divide_5th
FROM
    divide_1st
    INNER JOIN divide_2nd
    ON divide_1st.university_type = divide_2nd.university_type
    AND divide_1st.year = divide_2nd.year
    INNER JOIN divide_3rd
    ON divide_1st.university_type = divide_3rd.university_type
    AND divide_1st.year = divide_3rd.year
    INNER JOIN divide_4th
    ON divide_1st.university_type = divide_4th.university_type
    AND divide_1st.year = divide_4th.year
    INNER JOIN divide_5th
    ON divide_1st.university_type = divide_5th.university_type
    AND divide_1st.year = divide_5th.year
