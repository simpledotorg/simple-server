# frozen_string_literal: true

class Reports::ProgressMonthlyFollowUpsComponent < ViewComponent::Base
  include AssetsHelper
  include ActionView::Helpers::NumberHelper

  attr_reader :monthly_follow_ups, :period_info, :region, :diagnosis

  def initialize(monthly_follow_ups:, period_info:, region:, diagnosis: nil)
    @monthly_follow_ups = monthly_follow_ups
    @period_info = period_info
    @region = region
    @diagnosis = diagnosis || "Hypertension"
  end
end
