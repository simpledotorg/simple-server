# frozen_string_literal: true

class ProgressTab::DailyProgressComponentV2 < ApplicationComponent
  include AssetsHelper
  include ProgressTabHelper
  include Memery

  # We use 29 here because we also show today, so its 30 days including today
  DAYS_AGO = 29
  DATE_FORMAT = ApplicationHelper::STANDARD_DATE_DISPLAY_FORMAT

  attr_reader :service, :current_user, :title, :subtitle, :region

  def initialize(service:, current_user:, title:, subtitle:)
    @service = service
    @now = Date.current
    @start = @now - DAYS_AGO
    @region = service.region
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

  def is_data_available_for(date)
    data_available_for_dates.include?(date.to_date)
  end

  def display_date(date)
    date.strftime(DATE_FORMAT)
  end

  def diagnosis_headers
    {
      hypertension: I18n.t("progress_tab.diagnoses.hypertension_only"),
      diabetes: I18n.t("progress_tab.diagnoses.diabetes_only"),
      hypertension_and_diabetes: I18n.t("progress_tab.diagnoses.hypertension_and_diabetes")
    }
  end

  delegate :daily_follow_ups_breakdown, :daily_registrations_breakdown, to: :service

  private

  memoize def data_available_for_dates
    daily_registrations_breakdown.keys
  end
end
