module MonthHelper
  def month_start(year, month)
    Time.new(year, month)
  end

  def previous_year_and_month(year, month, n=1)
    month_start = month_start(year, month) - n.months
    [month_start.year, month_start.month]
  end

  def month_short_name(year, month)
    month_start(year, month).strftime("%b")
  end

  def month_short_name_and_year(year, month)
    month_start(year, month).strftime("%b-%Y")
  end

  def last_n_months(n)
    (0..n-1).map do |i|
      month_start = Time.current.beginning_of_month - i.months
      [month_start.year, month_start.month]
    end
  end
end
