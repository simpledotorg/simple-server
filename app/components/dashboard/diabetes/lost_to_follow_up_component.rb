class Dashboard::Diabetes::LostToFollowUpComponent < ApplicationComponent
  attr_reader :region, :data, :period

  def initialize(region:, data:, period:)
    @region = region
    @data = data
    @period = period
  end

  def cumulative_assigned_patients
    data.dig(:ltfu_trend, :cumulative_assigned_patients, period)
  end

  def ltfu_patient_rate
    data.dig(:ltfu_trend, :ltfu_patients_rate, period)
  end

  def current_ltfu_patients
    data.dig(:ltfu_trend, :ltfu_patients, period)
  end
end
