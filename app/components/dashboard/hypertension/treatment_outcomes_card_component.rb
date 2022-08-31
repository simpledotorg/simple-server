class Dashboard::Hypertension::TreatmentOutcomesCardComponent < ApplicationComponent
  attr_reader :data, :region, :period

  def initialize(data:, region:, period:)
    @data = data
    @region = region
    @period = period
  end

  def graph_data
    {adjustedPatientCounts: data[:adjusted_patient_counts],
     controlRate: data[:controlled_patients_rate],
     controlledPatients: data[:controlled_patients],
     uncontrolledPatients: data[:uncontrolled_patients],
     uncontrolledRate: data[:uncontrolled_patients_rate],
     missedVisits: data[:missed_visits],
     missedVisitsRate: data[:missed_visits_rate],
     visitButNoBPMeasure: data[:visited_without_bp_taken],
     visitButNoBPMeasureRate: data[:visited_without_bp_taken_rates],
     **period_data}
  end

  def treatment_outcomes
    [{key: "missedVisitsRate",
      count: "missedVisits",
      class: "c-blue",
      title: "Missed visits",
      tooltip: {
        "Numerator" => t("missed_visits_copy.numerator"),
        "Denominator" => t("denominator_copy", region_name: @region.name)
      }},
      {key: "visitButNoBPMeasureRate",
       count: "visitButNoBPMeasure",
       class: "c-grey-dark",
       title: "Visit but no BP taken",
       tooltip: {
         "Numerator" => t("visit_but_no_bp_taken_copy.numerator"),
         "denominator" => t("denominator_copy", region_name: @region.name)
       }},
      {key: "uncontrolledRate",
       count: "uncontrolledPatients",
       class: "c-red",
       title: "BP not controlled".html_safe,
       tooltip: {
         "Numerator" => t("bp_not_controlled_copy.numerator"),
         "Denominator" => t("denominator_copy", region_name: @region.name)
       }},
      {key: "controlRate",
       count: "controlledPatients",
       title: "BP controlled",
       class: "c-amber",
       tooltip: {
         "Numerator" => t("bp_controlled_copy.numerator"),
         "Denominator" => t("denominator_copy", region_name: @region.name)
       }}]
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
