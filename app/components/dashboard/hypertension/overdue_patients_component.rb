class Dashboard::Hypertension::OverduePatientsComponent < ApplicationComponent
  attr_reader :region, :data, :period

  def initialize(region:, data:, period:, with_non_contactable:)
    @region = region
    @data = data
    @period = period
    @contactable = !with_non_contactable
  end

  def graph_data
    {
      assignedPatients: data[:cumulative_assigned_patients],
      overduePatients: @contactable ? data[:contactable_overdue_patients] : data[:overdue_patients],
      overduePatientsPercentage: @contactable ? data[:contactable_overdue_patients_rates] : data[:overdue_patients_rates],
      **period_data
    }
  end

  private

  def period_data
    {endDate: period_info(:name)}
  end

  def period_info(key)
    data[:period_info].map { |k, v| [k, v[key]] }.to_h
  end
end
