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

  def analytics_month_totals(analytics, metric, month)
    dash_if_zero(analytics.sum { |_, row| row.dig(metric, month) || 0 })
  end
end
