module DashboardHelper
  def lighten_if_zero(value)
    value&.positive? ? value : content_tag(:span, value, class: "zero")
  end

  def analytics_date_format(time)
    time.strftime('%Y-%m-%d')
  end

  def range_for_quarter(offset)
    date = Date.today + (3 * offset).months
    { from_time: date.at_beginning_of_quarter,
      to_time: date.at_end_of_quarter }
  end

  def label_for_quarter(range)
    quarter = range[:to_time].month / 3
    year = range[:to_time].year

    "Q#{quarter} #{year}"
  end
end
