class Dashboard::PatientBreakdownComponent < ApplicationComponent
  attr_reader :region, :data, :period, :population_coverage_data, :curent_admin

  def initialize(region:, data:, period:)
    @region = region
    @data = data
    @period = period
  end

  # TODO: Remove dead patient count from assigned patient count
  def total_assigned_excluding_dead_patients
    data.dig(:cumulative_assigned_diabetes_patients, period)
  end

  def total_registered_patients
    data.dig(:cumulative_diabetes_registrations, period)
  end

  def patients_under_care
    data.dig(:diabetes_under_care, period)
  end

  def ltfu_patients
    data.dig(:diabetes_ltfu_patients, period)
  end

  def dead_patients
    data.dig(:diabetes_dead, period)
  end
end
