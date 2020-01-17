module QuarterHelper
  def quarter(date)
    ((date.month - 1) / 3) + 1
  end

  def current_quarter
    quarter(Date.current)
  end

  def previous_year_and_quarter(year = Time.current.year, quarter = quarter(Time.current))
    return [year - 1, 4] if quarter == 1

    [year, quarter - 1]
  end

  def quarter_string(date)
    year = date.year
    quarter = quarter(date)

    "#{year} Q#{quarter}"
  end

  def quarter_range_string(date, format)
    quarter = quarter(date)
    year = date.year
    "#{quarter_start(year, quarter).strftime(format)} - #{quarter_end(year, quarter).strftime(format)}"
  end

  def current_year
    Date.current.year
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
