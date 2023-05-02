# frozen_string_literal: true

class Reports::ProgressMonthlyFollowUpsComponent < ViewComponent::Base
  include AssetsHelper
  include ActionView::Helpers::NumberHelper

  attr_reader :monthly_follow_ups, :period_info, :region

  def initialize(monthly_follow_ups:, period_info:, region:)
    @monthly_follow_ups = monthly_follow_ups
    @period_info = period_info
    @region = region
  end
end
