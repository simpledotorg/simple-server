# frozen_string_literal: true

module MonthHelper
  def month_start(year, month)
    Time.new(year, month)
  end

  def local_month_start(year, month)
    Time.zone.local(year, month)
  end

  def local_month_end(year, month)
    local_month_start(year, month).end_of_month
  end

  def month_short_name(month_start)
    month_start.strftime("%b")
  end

  def month_short_name_and_year(month_start)
    month_start.strftime("%b-%Y")
  end

  def moy_to_date(year, moy)
    Date.civil(year.to_i, moy.to_i)
  end

  def last_n_months(n:, inclusive: false, end_of_month: false)
    range = inclusive ? (0..(n - 1)) : (1..n)

    range.map do |i|
      if end_of_month
        Time.current.end_of_month.advance(months: -i)
      else
        Time.current.beginning_of_month.advance(months: -i)
      end
    end
  end
end
