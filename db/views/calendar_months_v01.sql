WITH month_dates AS (
    SELECT date(generate_series) AS month_date
    FROM generate_series('2018-01-01', now(), '1 month')
)

SELECT
    month_date,
    EXTRACT(MONTH from month_date) as month,
    EXTRACT(QUARTER from month_date) as quarter,
    EXTRACT(YEAR FROM month_date) as year
FROM month_dates;