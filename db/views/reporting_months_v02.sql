WITH month_dates AS (
    SELECT date(generate_series) AS month_date
    FROM generate_series('2018-01-01', now(), '1 month')
)

SELECT
    month_date,
    to_char(month_date, 'YYYY-MM') as month_string,
    EXTRACT(MONTH from month_date) as month,
    to_char(month_date, 'YYYY-Q') as quarter_string,
    EXTRACT(QUARTER from month_date) as quarter,
    EXTRACT(YEAR FROM month_date) as year
FROM month_dates;
