class ProgressTab::Diabetes::ControlComponent < ApplicationComponent
  include AssetsHelper
  include FlipperHelper

  attr_reader :control_rates, :controlled, :adjusted_patients, :period_info, :region

  def initialize(controlled_rates:, controlled:, adjusted_patients:, period_info:, region:, use_who_standard: nil)
    @control_rates = controlled_rates
    @controlled = controlled
    @adjusted_patients = adjusted_patients
    @period_info = period_info
    @region = region
    @use_who_standard = resolve_use_who_standard(use_who_standard)

    set_locale_values
  end

  private

  def set_locale_values
    if @use_who_standard
      @controlled_threshold_long = t("bs_below_200_copy.numerator_fbs")
      @controlled_threshold_short = t("bs_below_200_copy.reports_card_title_fbs")
      @controlled_threshold_bar = t("bs_below_200_copy.report_card_lower_bar_fbs")
      @subtitle_text = t(
        "bs_below_200_copy.reports_card_subtitle_dm_fbs",
        region_name: @region.name,
        diagnosis: "Diabetes",
        controlled_threshold: @controlled_threshold_long
      )
      @numerator_text = t("bs_below_200_copy.numerator_dm_fbs")
    else
      @controlled_threshold_long = t("bs_below_200_copy.numerator")
      @controlled_threshold_short = t("bs_below_200_copy.reports_card_title")
      @controlled_threshold_bar = t("bs_below_200_copy.report_card_lower_bar")
      @subtitle_text = t(
        "bs_below_200_copy.reports_card_subtitle_dm",
        region_name: @region.name,
        diagnosis: "Diabetes",
        controlled_threshold: @controlled_threshold_long
      )
      @numerator_text = t("bs_below_200_copy.numerator")
    end

    @denominator_text = t(
      "progress_tab.diagnosis_report.patient_treatment_outcomes.controlled_card.help_tooltip.denominator",
      facility_name: @region.name,
      diagnosis: "Diabetes"
    )
  end
end
