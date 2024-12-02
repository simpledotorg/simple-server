class ProgressTab::Diabetes::BloodSugar200To299Component < ApplicationComponent
  include AssetsHelper
  include ActionView::Helpers::NumberHelper

  attr_reader :uncontrolled_rates, :uncontrolled, :adjusted_patients, :period_info, :region

  def initialize(uncontrolled_rates:, uncontrolled:, adjusted_patients:, period_info:, region:)
    @uncontrolled_rates = uncontrolled_rates
    @uncontrolled = uncontrolled
    @adjusted_patients = adjusted_patients
    @period_info = period_info
    @region = region
  end

  def uncontrolled_threshold_key
    CountryConfig.current_country?(LK_DIABETES_CONSTANT) ? "lk_diabetes_uncontrolled" : "diabetes_uncontrolled"
  end

  def uncontrolled_threshold_long
    I18n.t("progress_tab.diagnosis_report.diagnosis_thresholds.#{uncontrolled_threshold_key}_long")
  end

  def uncontrolled_threshold_title
    I18n.t("progress_tab.diagnosis_report.diagnosis_thresholds.#{uncontrolled_threshold_key}_title")
  end

  def uncontrolled_threshold_short
    I18n.t("progress_tab.diagnosis_report.diagnosis_thresholds.#{uncontrolled_threshold_key}_short")
  end

  def uncontrolled_bar
    t("progress_tab.diagnosis_report.diagnosis_thresholds.#{uncontrolled_threshold_key}_bar")
  end

  def subtitle_text
    I18n.t("progress_tab.diagnosis_report.patient_treatment_outcomes.uncontrolled_card.subtitle",
      facility_name: region.name, diagnosis: "Diabetes", uncontrolled_threshold: uncontrolled_threshold_long)
  end

  def numerator_text
    I18n.t("progress_tab.diagnosis_report.patient_treatment_outcomes.uncontrolled_card.help_tooltip.numerator",
      uncontrolled_threshold: uncontrolled_threshold_long)
  end

  def denominator_text
    I18n.t("progress_tab.diagnosis_report.patient_treatment_outcomes.uncontrolled_card.help_tooltip.denominator",
      facility_name: region.name, diagnosis: "Diabetes")
  end
end
