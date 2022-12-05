# frozen_string_literal: true

class ProgressTab::YearlyReportComponentV2 < ApplicationComponent
  include AssetsHelper
  include ProgressTabHelper
  include Memery

  MONTH_DATE_FORMAT = Date::DATE_FORMATS[:mon_year]
  SIMPLE_START_YEAR = 2018
  FINANCIAL_YEAR_START_MONTH = 4
  YEAR_START_MONTH = 1
  # Formula to calculate the date after a year including today
  ONE_YEAR = 12.months - 1.day

  attr_reader :service, :current_user, :title, :subtitle, :region

  def initialize(service, current_user, title:, subtitle:)
    @service = service
    @current_user = current_user
    @title = title
    @subtitle = subtitle
    @region = service.region
  end

  def render?
    Flipper.enabled?(:new_progress_tab_v2, current_user) || Flipper.enabled?(:new_progress_tab_v2)
  end

  memoize def report_in_financial_year?
    Flipper.enabled?(:yearly_reports_start_from_april, @current_user)
  end

  def is_data_available_for(year)
    yearly_registrations_breakdown[year].present?
  end

  memoize def last_n_years
    years = (SIMPLE_START_YEAR..Date.current.year).to_a.reverse
    if report_in_financial_year?
      years.push(SIMPLE_START_YEAR - 1)
    end

    years.each_with_object({}) do |year, hsh|
      hsh[year] = display_year(year)
    end
  end

  def display_date(period)
    period.to_date.strftime(MONTH_DATE_FORMAT)
  end

  def display_year(year)
    start_date = if report_in_financial_year?
      Date.new(year, FINANCIAL_YEAR_START_MONTH)
    else
      Date.new(year, YEAR_START_MONTH)
    end
    end_date = start_date + ONE_YEAR
    "#{display_date(start_date)} to #{display_date(end_date)}"
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
