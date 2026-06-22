class Dashboard::Diabetes::TreatmentOutcomesCardComponent < ApplicationComponent
  attr_reader :data
  attr_reader :region
  attr_reader :period
  attr_reader :with_ltfu
  attr_reader :use_who_standard

  def initialize(data:, region:, period:, with_ltfu: false, use_who_standard: false)
    @data = data
    @region = region
    @period = period
    @with_ltfu = with_ltfu
    @use_who_standard = use_who_standard
  end

  def graph_data
    {bsBelow200Rate: data[:bs_below_200_rates],
     bs200to300Rate: data[:bs_200_to_300_rates],
     bsOver300Rate: data[:bs_over_300_rates],
     visitButNoBSMeasureRate: data[:visited_without_bs_taken_rates],
     diabetesMissedVisitsRate: data[:diabetes_missed_visits_rates],
     adjustedDiabetesPatientCounts: data[:adjusted_diabetes_patient_counts],
     bsBelow200Patients: data[:bs_below_200_patients],
     bs200to300Patients: data[:bs_200_to_300_patients],
     bsOver300Patients: data[:bs_over_300_patients],
     diabetesMissedVisits: data[:diabetes_missed_visits],
     visitButNoBSMeasure: data[:visited_without_bs_taken],
     **period_data}
  end

  def treatment_outcomes
    [{key: "diabetesMissedVisitsRate",
      count: "diabetesMissedVisits",
      class: "c-blue",
      outcome: :missed_visits},
      {key: "visitButNoBSMeasureRate",
       count: "visitButNoBSMeasure",
       class: "c-grey-dark",
       outcome: :visit_no_bs},
      {key: "bsOver300Rate",
       count: "bsOver300Patients",
       class: "c-red",
       outcome: :bs_over_300},
      {key: "bs200to300Rate",
       count: "bs200to300Patients",
       class: "c-amber",
       outcome: :bs_200_to_299},
      {key: "bsBelow200Rate",
       count: "bsBelow200Patients",
       class: "c-green-dark",
       outcome: :bs_below_200}]
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
