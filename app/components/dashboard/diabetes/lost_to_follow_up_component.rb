class Dashboard::Diabetes::LostToFollowUpComponent < ApplicationComponent
  attr_reader :region, :data, :period

  def initialize(region:, data:, period:)
    @region = region
    @data = data
    @period = period
  end

  def graph_data
    {
      ltfuPatients: data.dig(:ltfu_trend, :ltfu_patients),
      ltfuPatientsRate: data.dig(:ltfu_trend, :ltfu_patients_rate),
      cumulativeAssignedPatients: data.dig(:ltfu_trend, :cumulative_assigned_patients),
      **period_data
    }
  end

  private

  def period_data
    {
      startDate: period_info(:bp_control_start_date),
      endDate: period_info(:bp_control_end_date),
      registrationDate: period_info(:bp_control_registration_date)
    }
  end

  def period_info(key)
    data[:period_info].map { |k, v| [k, v[key]] }.to_h
  end
end
