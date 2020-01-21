module MonthHelper
  def beginning_of_month(year, month)
    Time.new(year, month)
  end

  def previous_year_and_month(year, month)
    beginning_of_month = beginning_of_month(year, month) - 1.month
    [beginning_of_month.year, beginning_of_month.month]
  end

  def month_short_string(year, month)
    beginning_of_month(year, month).strftime("%b-%Y")
  end

  def last_n_months(n)
    (0..n-1).map do |i|
      beginning_of_month = Time.current.beginning_of_month - i.months
      [beginning_of_month.year, beginning_of_month.month]
    end
  end
end
