class Dashboard::Hypertension::OverduePatientsCalledComponent < ApplicationComponent
  def initialize(region:, data:, period:, with_removed_from_overdue_list:)
    @region = region
    @data = data
    @period = period
    @with_removed_from_overdue_list = with_removed_from_overdue_list
    @with_removed_from_overdue_list = with_removed_from_overdue_list
    @rates = gen_rates
  end

  def graph_data
    # TODO: Implement toggle logic. We can reuse the keys in the graph_data but inject the
    # filtered / non filtered data based on the toggle
    {
      overduePatients: @rates.map { |k, v| {k => v[:overduePatients]} }.reduce(:merge),
      overduePatientsCalled: @rates.map { |k, v| {k => v[:overduePatientsCalled]} }.reduce(:merge),
      overduePatientsCalledRates: @rates.map { |k, v| {k => v[:overduePatientsCalledRates]} }.reduce(:merge),
      startDate: @period.advance(months: -12),
      endDate: @periods
    }
  end

  def gen_rates
    periods
      .reduce({}) { |merged_values, val| merged_values.merge({val => rand(1..10_000)}) }
      .map do |period, value|
      overdue_count = rand(0..value)
      rate = overdue_count * 100 / value
      {period => {overduePatients: value,
                  overduePatientsCalled: overdue_count,
                  overduePatientsCalledRates: rate}}
    end
      .reduce(:merge)
  end

  def periods
    start_period = @period.advance(months: -12)
    Range.new(start_period, @period)
  end
end
