# frozen_string_literal: true

# NOTE: The Quarter value object is preferred over these static methods, consider using
# that object for a more object oriented apporach if you need to iterate over quarters or
# get previous / next quarters.
module QuarterHelper
  module_function

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

  def next_year_and_quarter(year = Time.current.year, quarter = quarter(Time.current))
    return [year + 1, 1] if quarter == 4

    [year, quarter + 1]
  end

  def current_year_and_quarter
    [current_year, current_quarter]
  end

  def quarter_string(date)
    year = date.year
    quarter = quarter(date)

    "Q#{quarter}-#{year}"
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
    Date.new(year, quarter_month).beginning_of_month
  end

  def quarter_start(year, quarter)
    quarter_datetime(year, quarter).beginning_of_quarter
  end

  def quarter_end(year, quarter)
    quarter_datetime(year, quarter).end_of_quarter
  end

  def local_quarter_start(year, quarter)
    quarter_month = ((quarter - 1) * 3) + 1
    Time.zone.local(year, quarter_month).beginning_of_quarter
  end

  def local_quarter_end(year, quarter)
    local_quarter_start(year, quarter).end_of_quarter
  end

  def last_n_quarters(n:, inclusive: false)
    initial_quarter = if inclusive
      [current_year, current_quarter]
    else
      previous_year_and_quarter(current_year, current_quarter)
    end

    (1...n).reduce([initial_quarter]) do |quarter_list, _|
      quarter_list << previous_year_and_quarter(*quarter_list.last)
    end
  end
end
