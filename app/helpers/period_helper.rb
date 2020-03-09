module PeriodHelper
  def period_list(period, last_n)
    case period
      when :quarter then
        last_n_quarters(n: last_n, inclusive: true)
      when :month then
        last_n_months(n: last_n, inclusive: true)
          .map { |month| [month.year, month.month] }
      when :day then
        last_n_days(n: last_n)
    end
  end

  def periods_as_sql_list(periods)
    periods.map { |year, period| "('#{year}', '#{period}')" }.join(',')
  end
end
