class Dashboard::Hypertension::CumulativeRegistrationsGraphComponent < ApplicationComponent
  attr_reader :data, :region, :period

  def initialize(data:, region:, period:)
    @data = data
    @region = region
    @period = period
  end

  def show_diagnosis_breakdown?
    @region.diabetes_management_enabled?
  end

  def graph_data
    {
      cumulativeRegistrations: data[:cumulative_registrations],
      monthlyRegistrations: data[:registrations],
      cumulativeHypertensionAndDiabetesRegistrations: data[:cumulative_hypertension_and_diabetes_registrations],
      cumulativeHypertensionOnlyRegistrations: cumulative_hypertension_only_registrations,
      **period_data
    }
  end

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

  def cumulative_hypertension_only_registrations
    cumulative_hypertension_registrations = data[:cumulative_registrations]
    cumulative_hypertension_and_diabetes_registrations = data[:cumulative_hypertension_and_diabetes_registrations]

    cumulative_hypertension_and_diabetes_registrations.map do |period, value|
      [period, cumulative_hypertension_registrations[period] - value]
    end.to_h
  end
end
