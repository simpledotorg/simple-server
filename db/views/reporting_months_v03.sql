WITH month_dates AS (
    SELECT date(generate_series) AS month_date
    FROM generate_series('2018-01-01'::date, current_date, '1 month')
)

SELECT
    month_date,
    EXTRACT(MONTH from month_date) as month,
    EXTRACT(QUARTER from month_date) as quarter,
    EXTRACT(YEAR FROM month_date) as year,
    to_char(month_date, 'YYYY-MM') as month_string,
    to_char(month_date, 'YYYY-Q') as quarter_string
FROM month_dates;
