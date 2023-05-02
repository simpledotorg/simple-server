# frozen_string_literal: true

class Reports::ProgressTotalRegistrationsComponent < ViewComponent::Base
  include AssetsHelper
  include ActionView::Helpers::NumberHelper

  attr_reader :total_registrations, :period_info, :region

  def initialize(total_registrations:, period_info:, region:)
    @total_registrations = total_registrations
    @period_info = period_info
    @region = region
  end
end
