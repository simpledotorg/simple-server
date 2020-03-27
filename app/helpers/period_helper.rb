module PeriodHelper
  def period_list(period, last_n)
    case period
      when :quarter
        last_n_quarters(n: last_n, inclusive: true)
      when :month
        last_n_months(n: last_n, inclusive: true)
          .map { |month| [month.year, month.month] }
      when :day
        last_n_days(n: last_n, inclusive: true)
    end
  end

  def period_list_as_dates(period, last_n)
    period_list(period, last_n).sort.reverse.map do |date|
      case period
        when :month
          moy_to_date(*date)
        when :day
          doy_to_date(*date)
        else
          nil
      end
    end
  end

  def periods_as_sql_list(periods)
    periods.map { |year, period| "('#{year}', '#{period}')" }.join(',')
  end
end
