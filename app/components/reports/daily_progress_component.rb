# frozen_string_literal: true

class Reports::DailyProgressComponent < ViewComponent::Base
  include AssetsHelper

  # We use 29 here because we also show today, so its 30 days including today
  DAYS_AGO = 29
  DAY_FORMAT = ApplicationHelper::STANDARD_DATE_DISPLAY_FORMAT

  attr_reader :service

  def initialize(service, last_updated_at)
    @service = service
    @now = Date.current
    @start = @now - DAYS_AGO
    @region = service.region
    @last_updated_at = DateTime.parse(last_updated_at).to_date.strftime("%d-%b-%y at %I:%M %P")
  end

  delegate :daily_follow_ups, :daily_registrations, to: :service

  def last_30_days
    (@start..@now).to_a.reverse
  end

  def display_date(date)
    date.strftime(DAY_FORMAT)
  end
end
