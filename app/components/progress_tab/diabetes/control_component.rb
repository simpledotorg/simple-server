class ProgressTab::Diabetes::ControlComponent < ApplicationComponent
  include AssetsHelper

  attr_reader :control_rates, :controlled, :adjusted_patients, :period_info, :region

  def initialize(controlled_rates:, controlled:, adjusted_patients:, period_info:, region:)
    @control_rates = controlled_rates
    @controlled = controlled
    @adjusted_patients = adjusted_patients
    @period_info = period_info
    @region = region
  end

  def controlled_threshold_key
    CountryConfig.current_country?(LK_DIABETES_CONSTANT) ? "lk_diabetes_controlled" : "diabetes_controlled"
  end

  def controlled_threshold_long
    t("progress_tab.diagnosis_report.diagnosis_thresholds.#{controlled_threshold_key}_long")
  end

  def controlled_threshold_short
    t("progress_tab.diagnosis_report.diagnosis_thresholds.#{controlled_threshold_key}_short")
  end

  def controlled_bar
    t("progress_tab.diagnosis_report.diagnosis_thresholds.#{controlled_threshold_key}_bar")
  end

  def subtitle_text
    t("progress_tab.diagnosis_report.patient_treatment_outcomes.controlled_card.subtitle", facility_name: @region.name, diagnosis: "Diabetes", controlled_threshold: controlled_threshold_long)
  end

  def numerator_text
    t("progress_tab.diagnosis_report.patient_treatment_outcomes.controlled_card.help_tooltip.numerator", controlled_threshold: controlled_threshold_long)
  end

  def denominator_text
    t("progress_tab.diagnosis_report.patient_treatment_outcomes.controlled_card.help_tooltip.denominator", facility_name: @region.name, diagnosis: "Diabetes")
  end
end
