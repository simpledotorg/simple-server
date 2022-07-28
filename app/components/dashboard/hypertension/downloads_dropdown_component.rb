class Dashboard::Hypertension::DownloadsDropdownComponent < ApplicationComponent
  include QuarterHelper

  attr_reader :region, :report_scope, :period, :current_admin

  def initialize(region:, report_scope:, period:, current_admin:)
    @region = region
    @period = period
    @report_scope = report_scope
    @current_admin = current_admin
  end

  def region_download_path
    reports_region_download_path(
      region,
      report_scope: report_scope,
      period: :quarter,
      format: :csv
    )
  end

  def monthly_district_report_path
    reports_region_hypertension_monthly_district_report_path(
      region,
      report_scope: report_scope,
      period: period.attributes,
      format: :zip
    )
  end

  def monthly_district_data_path
    reports_region_hypertension_monthly_district_data_path(
      region,
      report_scope: report_scope,
      period: period.attributes,
      format: :csv
    )
  end

  def monthly_state_data_path
    reports_region_hypertension_monthly_state_data_path(
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

  def graphics_path(format)
    previous_quarter_year, previous_quarter = previous_year_and_quarter
    reports_graphics_path(
      region,
      report_scope: report_scope,
      quarter: previous_quarter,
      year: previous_quarter_year,
      format: format
    )
  end

  def show_monthly_district_report?
    region.district_region? && current_admin.feature_enabled?(:monthly_district_report)
  end

  def show_monthly_facility_data?
    region.district_region? && current_admin.feature_enabled?(:monthly_district_data_download)
  end

  def show_monthly_state_data?
    region.state_region? && current_admin.feature_enabled?(:monthly_state_data_download)
  end

  def show_patient_line_list?
    region.region_type.in?(["district", "facility"]) && current_admin.can_access?(region.source, :view_pii)
  end
end
