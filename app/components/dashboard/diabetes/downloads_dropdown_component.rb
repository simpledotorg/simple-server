class Dashboard::Diabetes::DownloadsDropdownComponent < ApplicationComponent
  include QuarterHelper

  attr_reader :region, :period, :report_scope, :current_admin

  def initialize(region:, period:, report_scope:, current_admin:)
    @region = region
    @period = period
    @report_scope = report_scope
    @current_admin = current_admin
  end

  def monthly_state_data_path
    reports_region_diabetes_monthly_state_data_path(
      region,
      report_scope: report_scope,
      period: period.attributes,
      format: :csv
    )
  end

  def monthly_district_report_path
    reports_region_diabetes_monthly_district_report_path(
      region,
      report_scope: report_scope,
      period: period.attributes,
      format: :zip
    )
  end

  def monthly_district_data_path
    reports_region_diabetes_monthly_district_data_path(
      region,
      report_scope: report_scope,
      period: period.attributes,
      format: :csv
    )
  end

  def patient_line_list_path
    reports_patient_list_path(
      region,
      report_scope: report_scope
    )
  end
end
