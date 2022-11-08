# frozen_string_literal: true

class ProgressTab::YearlyReportComponentV2 < ApplicationComponent
  include AssetsHelper
  include ProgressTabHelper

  MONTH_DATE_FORMAT = Date::DATE_FORMATS[:month_year]

  attr_reader :service, :current_user, :title, :subtitle, :region

  def initialize(service, current_user, title:, subtitle:)
    @service = service
    @current_user = current_user
    @title = title
    @subtitle = subtitle
    @region = service.region
    @year_start_month = Flipper.enabled?(:progress_financial_year, @current_user) ? 4 : 1
  end

  def render?
    Flipper.enabled?(:new_progress_tab_v2, current_user) || Flipper.enabled?(:new_progress_tab_v2)
  end

  def last_n_years
    if Flipper.enabled?(:progress_financial_year, @current_user)
      (2017..Date.current.year).to_a.reverse
    else
      (2018..Date.current.year).to_a.reverse
    end
  end

  def display_date(period)
    period.to_date.strftime(MONTH_DATE_FORMAT)
  end

  def display_year(year)
    start_date = display_date(Date.new(year, @year_start_month))
    end_date = display_date(Date.new(year + 1, @year_start_month - 1))
    "#{start_date} to #{end_date}"
  end

  def total_registrations(date)
    service.yearly_total_registrations[date]
  end

  def total_follow_ups(date)
    service.yearly_total_follow_ups[date]
  end

  def diagnosis_headers
    {
      hypertension: I18n.t("progress_tab.diagnoses.hypertension_only"),
      diabetes: I18n.t("progress_tab.diagnoses.diabetes_only"),
      hypertension_and_diabetes: I18n.t("progress_tab.diagnoses.hypertension_and_diabetes")
    }
  end

  delegate :yearly_follow_ups_breakdown, :yearly_registrations_breakdown, to: :service
end
