# frozen_string_literal: true

module DayHelper
  def last_n_days(n:, inclusive: false)
    range = inclusive ? (0..(n - 1)) : (1..n)

    range.map do |i|
      [(Time.current - i.days).year, (Time.current - i.days).yday]
    end
  end

  def doy_to_date(year, doy)
    Date.ordinal(year.to_i, doy.to_i)
  end

  def doy_to_date_str(year, doy)
    doy_to_date(year, doy).strftime("%d-%b")
  end
end
