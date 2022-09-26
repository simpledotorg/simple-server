# frozen_string_literal: true

class ProgressTab::DailyProgressComponentV2 < ApplicationComponent
  include AssetsHelper
  include ProgressTabHelper

  # We use 29 here because we also show today, so its 30 days including today
  DAYS_AGO = 29
  DAY_FORMAT = ApplicationHelper::STANDARD_DATE_DISPLAY_FORMAT

  attr_reader :service, :current_user, :title, :subtitle, :region

  def initialize(service, last_updated_at, current_user, title:, subtitle:)
    @service = service
    @now = Date.current
    @start = @now - DAYS_AGO
    @region = service.region
    @last_updated_at = DateTime.parse(last_updated_at).to_date.strftime(DAY_FORMAT + " at %I:%M %P")
    @current_user = current_user
    @title = title
    @subtitle = subtitle
  end

  def render?
    Flipper.enabled?(:new_progress_tab_v2, current_user) || Flipper.enabled?(:new_progress_tab_v2)
  end

  def last_30_days
    (@start..@now).to_a.reverse.map { |date| display_date(date) }
  end

  def display_date(date)
    date.strftime(DAY_FORMAT)
  end

  delegate :diagnosis_headers, :daily_follow_ups_breakdown, :daily_registrations_breakdown, to: :service
end
