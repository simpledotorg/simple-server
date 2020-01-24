module MonthHelper
  def month_start(year, month)
    Time.new(year, month)
  end

  def month_short_name(month_start)
    month_start.strftime('%b')
  end

  def month_short_name_and_year(month_start)
    month_start.strftime('%b-%Y')
  end

  def last_n_months(n)
    (1..n).map do |i|
      Time.current.beginning_of_month - i.months
    end
  end
end
