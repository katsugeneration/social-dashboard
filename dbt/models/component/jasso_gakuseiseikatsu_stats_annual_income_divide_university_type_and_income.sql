{{ config(
    materialized = 'view'
) }} CREATE temp FUNCTION range_sum_value(
    cumrate float64,
    rate float64,
    range_num int64,
    min_num int64,
    range_value int64
) returns float64 AS (
    range_value * IF(
        min_num < cumrate - rate
        AND cumrate <= min_num + range_num,
        rate,
        IF(
            cumrate <= min_num
            OR cumrate - rate > min_num + range_num,
            0,
            IF(
                cumrate - rate <= min_num,
                cumrate - min_num,
                rate - cumrate + min_num + range_num
            )
        )
    )
);
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
)
SELECT
    university_type,
    YEAR,
    '年収五分位1' AS quintile,
    SUM(
        range_sum_value(
            cumrate,
            rate,
            20,
            0,
            range_value
        )
    ) / 20 AS VALUE
FROM
    cum_rates
GROUP BY
    university_type,
    YEAR
UNION ALL
SELECT
    university_type,
    YEAR,
    '年収五分位2' AS quintile,
    SUM(
        range_sum_value(
            cumrate,
            rate,
            20,
            20,
            range_value
        )
    ) / 20 AS VALUE
FROM
    cum_rates
GROUP BY
    university_type,
    YEAR
UNION ALL
SELECT
    university_type,
    YEAR,
    '年収五分位3' AS quintile,
    SUM(
        range_sum_value(
            cumrate,
            rate,
            20,
            40,
            range_value
        )
    ) / 20 AS VALUE
FROM
    cum_rates
GROUP BY
    university_type,
    YEAR
UNION ALL
SELECT
    university_type,
    YEAR,
    '年収五分位4' AS quintile,
    SUM(
        range_sum_value(
            cumrate,
            rate,
            20,
            60,
            range_value
        )
    ) / 20 AS VALUE
FROM
    cum_rates
GROUP BY
    university_type,
    YEAR
UNION ALL
SELECT
    university_type,
    YEAR,
    '年収五分位5' AS quintile,
    SUM(
        range_sum_value(
            cumrate,
            rate,
            20,
            80,
            range_value
        )
    ) / 20 AS VALUE
FROM
    cum_rates
GROUP BY
    university_type,
    YEAR
UNION ALL
SELECT
    university_type,
    YEAR,
    '平均' AS quintile,
    SUM(
        rate * range_value
    ) / 100 AS VALUE
FROM
    cum_rates
GROUP BY
    university_type,
    YEAR
