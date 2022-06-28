class Dashboard::Downloads::DropDownMenuComponent < ApplicationComponent
  include QuarterHelper
  attr_reader :quarterly_cohort_report_path, :region, :monthly_cohort_report_path, :current_admin, :monthly_district_report_path
  attr_reader :monthly_district_data_path, :monthly_state_data_path, :patient_list_path
  def initialize(
    region:,
    current_admin:,
    quarterly_cohort_report_path:,
    monthly_cohort_report_path:,
    monthly_district_report_path:,
    monthly_district_data_path:,
    monthly_state_data_path:,
    patient_list_path:
  )
    @region = region
    @current_admin = current_admin
    @quarterly_cohort_report_path = quarterly_cohort_report_path
    @monthly_cohort_report_path = monthly_cohort_report_path
    @monthly_district_report_path = monthly_district_report_path
    @monthly_district_data_path = monthly_district_data_path
    @monthly_state_data_path = monthly_state_data_path
    @patient_list_path = patient_list_path
  end
end
