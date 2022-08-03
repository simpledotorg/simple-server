class Dashboard::Diabetes::MissedVisitsGraphComponent < ApplicationComponent
  attr_reader :data
  attr_reader :region
  attr_reader :period
  attr_reader :with_ltfu

  def initialize(data:, region:, period:, with_ltfu: false)
    @data = data
    @region = region
    @period = period
    @with_ltfu = with_ltfu
  end

  def graph_data
    if with_ltfu
      return {
        adjustedDiabetesPatients: data[:adjusted_diabetes_patient_counts_with_ltfu],
        diabetesMissedVisitsGraphNumerator: data[:diabetes_missed_visits_with_ltfu],
        diabetesMissedVisitsGraphRate: data[:diabetes_missed_visits_with_ltfu_rates],
        **period_data
      }
    end

    {
      adjustedDiabetesPatients: data[:adjusted_diabetes_patient_counts],
      diabetesMissedVisitsGraphNumerator: data[:diabetes_missed_visits],
      diabetesMissedVisitsGraphRate: data[:diabetes_missed_visits_rates],
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
end
