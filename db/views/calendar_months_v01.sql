SELECT
  month_date,
  EXTRACT(MONTH from month_date) as month,
  EXTRACT(QUARTER from month_date) as quarter,
  EXTRACT(YEAR FROM month_date) as year
FROM (
  SELECT
    DATE '2018-01-01' + (interval '1' month * generate_series(0,month_count::int)) AS month_date
  FROM (
    SELECT EXTRACT(YEAR FROM diff) * 12 + EXTRACT(MONTH FROM diff) as month_count
    FROM ( SELECT age(current_timestamp, TIMESTAMP '2018-01-01 00:00:00') as diff ) td
  ) month_diffs
) calendar_dates
