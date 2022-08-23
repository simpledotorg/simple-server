class Dashboard::Diabetes::TreatmentOutcomesCardComponent < ApplicationComponent
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
      title: "Missed visits",
      tooltip: {
        numerator: t("diabetes_missed_visits_copy.numerator"),
        denominator: t("diabetes_denominator_copy", region_name: @region.name)
      }},
      {key: "visitButNoBSMeasureRate",
       count: "visitButNoBSMeasure",
       class: "c-grey-dark",
       title: "Visit but no blood sugar taken",
       tooltip: {
         numerator: t("visit_but_no_bs_taken_copy.numerator"),
         denominator: t("diabetes_denominator_copy", region_name: @region.name)
       }},
      {key: "bsOver300Rate",
       count: "bsOver300Patients",
       class: "c-red",
       title: "Blood sugar &ge;300".html_safe,
       tooltip: {
         numerator: t("bs_over_200_copy.bs_over_300.numerator"),
         denominator: t("diabetes_denominator_copy", region_name: @region.name)
       }},
      {key: "bs200to300Rate",
       count: "bs200to300Patients",
       title: "Blood sugar 200-299",
       class: "c-amber",
       tooltip: {numerator: t("bs_over_200_copy.bs_200_to_299.numerator"),
                 denominator: t("diabetes_denominator_copy", region_name: @region.name)}},
      {key: "bsBelow200Rate",
       count: "bsBelow200Patients",
       class: "c-green-dark",
       title: "Blood sugar &lt;200".html_safe,
       tooltip: {numerator: t("bs_below_200_copy.numerator"),
                 denominator: t("diabetes_denominator_copy", region_name: @region.name)}}]
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
