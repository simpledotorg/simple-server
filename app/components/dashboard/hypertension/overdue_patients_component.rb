class Dashboard::Hypertension::OverduePatientsComponent < ApplicationComponent
  def initialize(region:, data:, period:, with_removed_from_overdue_list:)
    @region = region
    @data = data
    @period = period
    @with_removed_from_overdue_list = with_removed_from_overdue_list
  end

  def graph_data
    {
      assigned_patients: periods.reduce({}) { |merged_values, p| merged_values.merge({p => rand(0..500)}) },
      filter_assigned_patients: {},
      overdue_patients: {},
      filter_overdue_patients: {},
      overdue_patients_rates: {},
      filter_overdue_patients_rates: {}
    }
  end

  def periods
    start_period = @period.advance(months: -12)
    Range.new(start_period, @period)
  end
end
