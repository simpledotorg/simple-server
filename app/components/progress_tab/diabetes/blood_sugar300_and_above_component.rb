# frozen_string_literal: true

class ProgressTab::Diabetes::BloodSugar300AndAboveComponent < ApplicationComponent
  include AssetsHelper
  include UseWhoStandard

  attr_reader :uncontrolled_rates, :uncontrolled, :adjusted_patients, :period_info, :region

  def initialize(uncontrolled_rates:, uncontrolled:, adjusted_patients:, period_info:, region:, use_who_standard: nil)
    @uncontrolled_rates = uncontrolled_rates
    @uncontrolled = uncontrolled
    @adjusted_patients = adjusted_patients
    @period_info = period_info
    @region = region
    @use_who_standard = resolve_use_who_standard(use_who_standard)
  end

  def uncontrolled_threshold_key
    @use_who_standard ? "_fbs" : ""
  end

  def uncontrolled_threshold_long
    t("bs_over_200_copy.bs_over_300.numerator#{uncontrolled_threshold_key}")
  end

  def uncontrolled_threshold_short
    t("bs_over_200_copy.bs_over_300.title_dm#{uncontrolled_threshold_key}")
  end

  def uncontrolled_bar
    t("bs_over_200_copy.bs_over_300.report_card_lower_bar#{uncontrolled_threshold_key}")
  end

  def subtitle_text
    t("bs_over_200_copy.bs_over_300.reports_card_subtitle#{uncontrolled_threshold_key}", region_name: @region.name, diagnosis: "Diabetes", controlled_threshold: uncontrolled_threshold_long)
  end

  def numerator_text
    t("bs_over_200_copy.bs_200_to_299.numerator_dm#{uncontrolled_threshold_key}")
  end

  def denominator_text
    t("bs_below_200_copy.denominator", facility_name: @region.name, diagnosis: "Diabetes")
  end
end
