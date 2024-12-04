class ProgressTab::Diabetes::ControlComponent < ApplicationComponent
  include AssetsHelper
  include UseWhoStandard

  attr_reader :control_rates, :controlled, :adjusted_patients, :period_info, :region

  def initialize(controlled_rates:, controlled:, adjusted_patients:, period_info:, region:, use_who_standard: nil)
    @control_rates = controlled_rates
    @controlled = controlled
    @adjusted_patients = adjusted_patients
    @period_info = period_info
    @region = region
    @use_who_standard = resolve_use_who_standard(use_who_standard)
  end

  def controlled_threshold_key
    @use_who_standard ? "_fbs" : ""
  end

  def controlled_threshold_long
    t("bs_below_200_copy.numerator#{controlled_threshold_key}")
  end

  def controlled_threshold_short
    t("bs_below_200_copy.reports_card_title#{controlled_threshold_key}")
  end

  def controlled_threshold_bar
    t("bs_below_200_copy.report_card_lower_bar#{controlled_threshold_key}")
  end

  def subtitle_text
    t("bs_below_200_copy.reports_card_subtitle_dm#{controlled_threshold_key}", region_name: @region.name, diagnosis: "Diabetes", controlled_threshold: controlled_threshold_long)
  end

  def numerator_text
    t("bs_below_200_copy.numerator_dm#{controlled_threshold_key}")
  end

  def denominator_text
    t("bs_below_200_copy.denominator", facility_name: @region.name, diagnosis: "Diabetes")
  end
end
