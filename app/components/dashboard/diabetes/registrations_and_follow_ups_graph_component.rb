class Dashboard::Diabetes::RegistrationsAndFollowUpsGraphComponent < ApplicationComponent
  attr_reader :region
  attr_reader :period
  attr_reader :data

  def initialize(region:, period:, data:)
    @region = region
    @period = period
    @data = data
  end

  def graph_data
    {cumulativeDiabetesRegistrations: data[:cumulative_diabetes_registrations],
     monthlyDiabetesRegistrations: data[:diabetes_registrations],
     monthlyDiabetesFollowups: data[:monthly_diabetes_followups],
     cumulativeHypertensionAndDiabetesRegistrations: data[:cumulative_hypertension_and_diabetes_registrations],
     cumulativeDiabetesOnlyRegistrations: cumulativeDiabetesOnlyRegistrations,
     **period_data}
  end

  private

  def period_data
    {
      periodName: period_info(:name),
      startDate: period_info(:bp_control_start_date),
      endDate: period_info(:bp_control_end_date),
      registrationDate: period_info(:bp_control_registration_date)
    }
  end

  def period_info(key)
    data[:period_info].map { |k, v| [k, v[key]] }.to_h
  end

  def cumulativeDiabetesOnlyRegistrations
    cumulative_diabetes_registrations = data[:cumulative_diabetes_registrations]
    cumulative_hypertension_and_diabetes_registrations = data[:cumulative_hypertension_and_diabetes_registrations]

    cumulative_hypertension_and_diabetes_registrations.map do |period, value|
      [period, cumulative_diabetes_registrations[period] - value]
    end.to_h
  end
end
