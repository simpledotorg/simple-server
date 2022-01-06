# frozen_string_literal: true

module PeriodHelper
  include MonthHelper

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
      end
    end
  end

  def periods_as_sql_list(periods)
    periods.map { |year, period| "('#{year}', '#{period}')" }.join(",")
  end
end
