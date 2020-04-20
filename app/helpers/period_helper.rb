module PeriodHelper
  include MonthHelper

  def all_period(period, date)
    case period
      when :quarter
        date.all_quarter
      when :month
        date.all_month
      when :day
        date.all_day
      else
        return nil
    end
  end

  def beginning_of_period(period, date)
    case period
      when :quarter
        date.beginning_of_quarter
      when :month
        date.beginning_of_month
      when :day
        date.beginning_of_day
      else
        return nil
    end
  end

  def last_n_periods(period, last_n)
    case period
      when :month
        last_n_months(n: last_n, inclusive: true)
      when :day
        beginning_of_period(period, (last_n - 1).days.ago).to_date..beginning_of_period(period, Time.current).to_date
      else
        nil
    end.to_a
  end

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
    period_list = period_list(period, last_n)
    return if period_list.blank?

    period_list.sort.reverse.map do |date|
      case period
        when :quarter
          quarter_datetime(*date)
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
