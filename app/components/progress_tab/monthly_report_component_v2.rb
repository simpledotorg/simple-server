# frozen_string_literal: true

class ProgressTab::MonthlyReportComponentV2 < ApplicationComponent
  include AssetsHelper
  include ProgressTabHelper
  include Memery

  MONTH_DATE_FORMAT = Date::DATE_FORMATS[:month_year]

  attr_reader :service, :current_user, :title, :subtitle, :region

  def initialize(service:, current_user:, title:, subtitle:)
    @service = service
    @current_user = current_user
    @title = title
    @subtitle = subtitle
    @region = service.region
  end

  def data_available?(date:)
    monthly_registrations_breakdown[Period.month(date.to_date)].present?
  end

  memoize def last_6_months
    service.range.to_a.reverse.map { |date| display_date(date) }
  end

  def display_date(period)
    period.to_date.strftime(MONTH_DATE_FORMAT)
  end

  def total_registrations(date)
    service.monthly_total_registrations[date]
  end

  def total_follow_ups(date)
    service.monthly_total_follow_ups[date]
  end

  def diagnosis_headers
    {
      hypertension: I18n.t("progress_tab.diagnoses.hypertension_only"),
      diabetes: I18n.t("progress_tab.diagnoses.diabetes_only"),
      hypertension_and_diabetes: I18n.t("progress_tab.diagnoses.hypertension_and_diabetes")
    }
  end

  delegate :monthly_follow_ups_breakdown, :monthly_registrations_breakdown, to: :service
end
