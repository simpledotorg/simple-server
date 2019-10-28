module DashboardHelper
  def dash_if_zero(value)
    zero?(value) ? "-" : value
  end

  def zero?(value)
    value.nil? || value.zero?
  end

  def dates_for_periods(period, previous_periods, from_date: Time.current)
    period_range = (0..(previous_periods - 1)).to_a.reverse

    if period == :month
      period_range.map { |n| n.months.ago.at_beginning_of_month.to_date }
    else
      # default to quarters
      period_range.map { |num_of_quarter| (from_date - (3 * num_of_quarter.months)).beginning_of_quarter.to_date }
    end
  end

  def format_period(period, value)
    period == :month ? value.strftime("%b %Y") : quarter_string(value)
  end

  def analytics_totals(analytics, metric, period)
    dash_if_zero(analytics.sum { |_, row| row.dig(metric, period) || 0 })
  end

  def calculate_percentage_for_analytics(analytics)
    total = analytics.values.sum
    return analytics if total == 0

    analytics.map { |k, v| [k, (v * 100.0) / total] }.to_h
  end

  def percentage_string(percentage)
    return '< 1%' if percentage < 1
    "#{percentage.round(0)}%"
  end
end
