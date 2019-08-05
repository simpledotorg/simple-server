module QuarterHelper
  def quarter(date)
    ((date.month - 1) / 3) + 1
  end

  def current_quarter
    quarter(Date.today)
  end

  def previous_quarter_and_year
    return [4, current_year - 1] if current_quarter == 1

    [current_quarter - 1, current_year]
  end

  def quarter_string(date)
    year = date.year
    quarter = quarter(date)

    "Q#{quarter} #{year}"
  end

  def quarter_range_string(date, format)
    quarter = quarter(date)
    year = date.year
    "#{quarter_start(year, quarter).strftime(format)} - #{quarter_end(year, quarter).strftime(format)}"
  end

  def current_year
    Date.today.year
  end

  def quarter_datetime(year, quarter)
    quarter_month = ((quarter - 1) * 3) + 1
    DateTime.new(year, quarter_month, 1)
  end

  def quarter_start(year, quarter)
    quarter_datetime(year, quarter).beginning_of_quarter
  end

  def quarter_end(year, quarter)
    quarter_datetime(year, quarter).end_of_quarter
  end
end
