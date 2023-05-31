class Dashboard::Hypertension::OverduePatientsComponent < ApplicationComponent
  attr_reader :region, :data, :period

  def initialize(region:, data:, period:, with_removed_from_overdue_list:)
    @region = region
    @data = data
    @period = period
    @with_removed_from_overdue_list = with_removed_from_overdue_list
    @rates = gen_rates
  end

  def graph_data
    # TODO: Implement toggle logic. We can reuse the keys in the graph_data but inject the
    # filtered / non filtered data based on the toggle
    {
      assignedPatients: data[:cumulative_assigned_patients],
      overduePatients: data[:overdue_patients],
      overduePatientsPercentage: data[:overdue_patients_rates],
      **period_data
    }
  end

  def gen_rates
    periods
      .reduce({}) { |merged_values, val| merged_values.merge({val => rand(1..10_000)}) }
      .map do |period, value|
        overdue_count = rand(0..value)
        rate = overdue_count * 100 / value
        {period => {assignedPatients: value,
                    overduePatients: overdue_count,
                    overduePatientsPercentage: rate}}
      end
      .reduce(:merge)
  end

  def periods
    start_period = @period.advance(months: -17)
    Range.new(start_period, @period)
  end

  private

  def period_data
    result = {
      endDate: period_info(:name)
    }
  end

  def period_info(key)
    data[:period_info].map { |k, v| [k, v[key]] }.to_h
  end
end
