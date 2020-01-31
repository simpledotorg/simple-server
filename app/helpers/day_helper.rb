module DayHelper
  def last_n_days(n:, include_today: false)
    range = include_today ? (0..(n - 1)) : (1..n)

    range.map do |i|
      [(Time.current - i.days).year, (Time.current - i.days).yday]
    end
  end

  def doy_to_date(year, doy)
    Date.ordinal(year, doy).strftime("%d-%b")
  end
end
