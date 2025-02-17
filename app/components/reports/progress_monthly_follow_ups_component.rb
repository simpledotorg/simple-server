# frozen_string_literal: true

class Reports::ProgressMonthlyFollowUpsComponent < ViewComponent::Base
  include AssetsHelper
  include ActionView::Helpers::NumberHelper

  attr_reader :monthly_follow_ups, :period_info, :region, :diagnosis, :diagnosis_subtitle_key

  def initialize(monthly_follow_ups:, period_info:, region:, diagnosis: nil)
    @monthly_follow_ups = monthly_follow_ups
    @period_info = period_info
    @region = region
    @diagnosis = diagnosis || "Hypertension"
    @diagnosis_subtitle_key = determine_subtitle_key
  end

  private

  def determine_subtitle_key
    if @diagnosis == "Hypertension"
      "progress_tab.diagnosis_report.monthly_follow_up_patients.subtitle"
    else
      "progress_tab.diagnosis_report.monthly_follow_up_patients.subtitle_dm"
    end
  end
end
