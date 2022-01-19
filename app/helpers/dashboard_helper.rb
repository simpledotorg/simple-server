module DashboardHelper
  def number_or_dash_with_delimiter(value, options = {})
    return "-" if value.blank? || value.zero?
    number_with_delimiter(value, options)
  end

  def number_or_zero_with_delimiter(value, options = {})
    return 0 unless value
    number_with_delimiter(value, options)
  end

  def number_to_percentage_with_symbol(value, options = {})
    symbol = value > 0 ? "+" : ""
    symbol + number_to_percentage(value, options)
  end

  def dash_if_blank_or_zero(value)
    return "-" if value.blank? || value.zero?
    value
  end

  def zero_if_blank_or_zero(value)
    return 0 if value.blank? || value.zero?
    value
  end

  def dates_for_periods(period, previous_periods, from_time: Time.current, include_current_period: false)
    period_range = (include_current_period ?
                      (0..previous_periods - 1) :
                      (1..previous_periods)).to_a.reverse

    if period == :month
      period_range.map { |n| (from_time - n.months).at_beginning_of_month.to_date }
    else
      # default to quarters
      period_range.map { |num_of_quarter| (from_time - (3 * num_of_quarter.months)).beginning_of_quarter.to_date }
    end
  end

  def format_period(period, value)
    period == :month ? value.strftime("%b-%Y") : quarter_string(value)
  end

  def multiline_format_period(period, value)
    format_period(period, value).gsub("-", "-\n")
  end

  def analytics_totals(analytics, metric, date)
    analytics.sum { |_, row| row.dig(metric, date) || 0 }
  end

  def calculate_percentage_for_analytics(analytics)
    total = analytics.values.sum
    return analytics if total == 0

    analytics.map { |k, v| [k, (v * 100.0) / total] }.to_h.with_indifferent_access
  end

  def percentage_string(percentage)
    return "0%" if percentage.zero?
    return "< 1%" if percentage < 1

    "#{percentage.round(0)}%"
  end

  def six_month_rate_change(facility, rate_name)
    raise ArgumentError, "rate_name should be a symbol" if rate_name.is_a?(String)
    @data_for_facility[facility.name][rate_name][@period] - @data_for_facility[facility.name][rate_name][@start_period] || 0
  end

  def facility_size_six_month_rate_change(facility_size_data, rate_name)
    facility_size_data[@period][rate_name] - facility_size_data[@start_period][rate_name] || 0
  end

  def total_estimated_hypertensive_population_copy(region)
    region_copy = "#{region.region_type}_copy"
    t("total_estimated_hypertensive_population.#{region_copy}", region_name: region.name)
  end

  def rounded_percentages(hsh)
    sorted_hsh = hsh.sort_by { |_, value| value.floor - value }.to_h
    rounded_down_percentages = sorted_hsh.map { |_, value| value.floor }
    difference_from_100 = 100 - rounded_down_percentages.reduce(:+)
    if difference_from_100 == 0 || difference_from_100 == 100
      sorted_hsh
    else
      sorted_hsh.each_with_index.map { |(key, value), index| [key, index < difference_from_100 ? value.floor + 1 : value.floor] }.to_h
    end
  end
end
