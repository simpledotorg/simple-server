module DashboardHelper
  def dash_if_zero(value)
    zero?(value) ? "-" : value
  end

  def zero?(value)
    value.nil? || value.zero?
  end

  def repeat_for_last(months: 3)
    (0..(months - 1)).to_a.reverse.each do |n|
      yield(n.months.ago.at_beginning_of_month.to_date)
    end
  end

  def repeat_for_last_n_quarters(from_date, n: 3)
    (0..n-1).to_a.each do |num_of_quarter|
      yield(from_date.prev_month(num_of_quarter * 3))
    end
  end

  def analytics_month_totals(analytics, metric, period)
    dash_if_zero(analytics.sum { |_, row| row.dig(metric, period) || 0 })
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
