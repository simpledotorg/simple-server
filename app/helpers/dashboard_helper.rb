module DashboardHelper
  def dash_if_zero(value)
    zero?(value) ? "-" : value
  end

  def zero_if_unavailable(value)
    zero?(value) ? "0" : value
  end

  def zero?(value)
    value.nil? || value.blank? || value.zero?
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
    period == :month ? value.strftime("%b %Y") : quarter_string(value)
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
    return '0%'   if percentage.zero?
    return '< 1%' if percentage < 1

    "#{percentage.round(0)}%"
  end
end
