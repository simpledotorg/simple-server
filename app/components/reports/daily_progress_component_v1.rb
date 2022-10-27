# frozen_string_literal: true

class Reports::DailyProgressComponentV1 < ViewComponent::Base
  include AssetsHelper
  include ApplicationHelper

  # We use 29 here because we also show today, so its 30 days including today
  DAYS_AGO = 29

  attr_reader :service, :current_user

  def initialize(service, last_updated_at, current_user)
    @service = service
    @now = Date.current
    @start = @now - DAYS_AGO
    @region = service.region
    @last_updated_on = display_date(last_updated_at)
    @last_updated_at = display_time(last_updated_at)
    @current_user = current_user
  end

  delegate :daily_follow_ups, :daily_registrations, to: :service

  def render?
    Flipper.enabled?(:new_progress_tab_v1, current_user) || Flipper.enabled?(:new_progress_tab_v1)
  end

  def last_30_days
    (@start..@now).to_a.reverse
  end
end
