# frozen_string_literal: true

class Reports::DailyProgressComponentV1 < ViewComponent::Base
  include AssetsHelper

  # We use 29 here because we also show today, so its 30 days including today
  DAYS_AGO = 29
  DATE_FORMAT = ApplicationHelper::STANDARD_DATE_DISPLAY_FORMAT
  TIME_FORMAT = ApplicationHelper::STANDARD_TIME_DISPLAY_FORMAT

  attr_reader :service, :current_user

  def initialize(service, last_updated_at, current_user)
    @service = service
    @now = Date.current
    @start = @now - DAYS_AGO
    @region = service.region
    @last_updated_on = DateTime.parse(last_updated_at).strftime(DATE_FORMAT)
    @last_updated_at = DateTime.parse(last_updated_at).strftime(TIME_FORMAT)
    @current_user = current_user
  end

  delegate :daily_follow_ups, :daily_registrations, to: :service

  def render?
    Flipper.enabled?(:new_progress_tab_v1, current_user) || Flipper.enabled?(:new_progress_tab_v1)
  end

  def last_30_days
    (@start..@now).to_a.reverse
  end

  def display_date(date)
    date.strftime(DATE_FORMAT)
  end
end
