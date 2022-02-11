# This emulates what progress tab shows in the API, but does it within our dashboard.
# The main purpose currently is to make it easier to develop on progress tab in dev.
class Reports::ProgressController < AdminController
  layout false
  before_action :require_feature_flag
  before_action :set_period
  before_action :find_region

  def show
    @current_facility = @region
    @user_analytics = UserAnalyticsPresenter.new(@region)
    @service = Reports::FacilityProgressService.new(current_facility, @period)

    if Flipper.enabled?(:new_progress_tab)
      @daily_periods = ["8-Feb-2022", "7-Feb-2022", "6-Feb-2022", "5-Feb-2022", "4-Feb-2022", "3-Feb-2022", "2-Feb-2022"]
      @daily_registered_patients = {
        "name" => "Registered patients",
        "total" => 7,
        "breakdown" => [
          { "title" => "Hypertension only", "value" => 2, "row_type" => :header },
          { "title" => "Male", "value" => 1, "row_type" => :secondary },
          { "title" => "Female", "value" => 1, "row_type" => :secondary },
          { "title" => "Transgender", "value" => 0, "row_type" => :secondary },
          { "title" => "Diabetes only", "value" => 1, "row_type" => :header },
          { "title" => "Male", "value" => 0, "row_type" => :secondary },
          { "title" => "Female", "value" => 1, "row_type" => :secondary },
          { "title" => "Transgender", "value" => 0, "row_type" => :secondary },
          { "title" => "Hypertension and diabetes", "value" => 4, "row_type" => :header },
          { "title" => "Male", "value" => 3, "row_type" => :secondary },
          { "title" => "Female", "value" => 0, "row_type" => :secondary },
          { "title" => "Transgender", "value" => 1, "row_type" => :secondary },
        ]
      }
      @daily_follow_up_patients = {
        "name" => "Follow-up patients",
        "total" => 15,
        "breakdown" => [
          { "title" => "Hypertension only", "value" => 3, "row_type" => :header },
          { "title" => "Male", "value" => 1, "row_type" => :secondary },
          { "title" => "Female", "value" => 2, "row_type" => :secondary },
          { "title" => "Transgender", "value" => 0, "row_type" => :secondary },
          { "title" => "Diabetes only", "value" => 2, "row_type" => :header },
          { "title" => "Male", "value" => 1, "row_type" => :secondary },
          { "title" => "Female", "value" => 1, "row_type" => :secondary },
          { "title" => "Transgender", "value" => 0, "row_type" => :secondary },
          { "title" => "Hypertension and diabetes", "value" => 10, "row_type" => :header },
          { "title" => "Male", "value" => 4, "row_type" => :secondary },
          { "title" => "Female", "value" => 4, "row_type" => :secondary },
          { "title" => "Transgender", "value" => 2, "row_type" => :secondary },
        ]
      }
      @monthly_periods = ["Feb-2022", "Jan-2022", "Dec-2021", "Nov-2021", "Oct-2021", "Sep-2021", "Aug-2021"]
      @monthly_registered_patients = {
        "name" => "Registered patients",
        "total" => 90,
        "breakdown" => [
          { "title" => "Hypertension only", "value" => 37, "row_type" => :header },
          { "title" => "Male", "value" => 15, "row_type" => :secondary },
          { "title" => "Female", "value" => 15, "row_type" => :secondary },
          { "title" => "Transgender", "value" => 7, "row_type" => :secondary },
          { "title" => "Diabetes only", "value" => 12, "row_type" => :header },
          { "title" => "Male", "value" => 5, "row_type" => :secondary },
          { "title" => "Female", "value" => 6, "row_type" => :secondary },
          { "title" => "Transgender", "value" => 1, "row_type" => :secondary },
          { "title" => "Hypertension and diabetes", "value" => 41, "row_type" => :header },
          { "title" => "Male", "value" => 19, "row_type" => :secondary },
          { "title" => "Female", "value" => 21, "row_type" => :secondary },
          { "title" => "Transgender", "value" => 1, "row_type" => :secondary },
        ]
      }
      @monthly_follow_up_patients = {
        "name" => "Follow-up patients",
        "total" => 158,
        "breakdown" => [
          { "title" => "Hypertension only", "value" => 15, "row_type" => :header },
          { "title" => "Male", "value" => 12, "row_type" => :secondary },
          { "title" => "Female", "value" => 3, "row_type" => :secondary },
          { "title" => "Transgender", "value" => 0, "row_type" => :secondary },
          { "title" => "Diabetes only", "value" => 16, "row_type" => :header },
          { "title" => "Male", "value" => 10, "row_type" => :secondary },
          { "title" => "Female", "value" => 5, "row_type" => :secondary },
          { "title" => "Transgender", "value" => 1, "row_type" => :secondary },
          { "title" => "Hypertension and diabetes", "value" => 127, "row_type" => :header },
          { "title" => "Male", "value" => 77, "row_type" => :secondary },
          { "title" => "Female", "value" => 49, "row_type" => :secondary },
          { "title" => "Transgender", "value" => 1, "row_type" => :secondary },
        ]
      }
      @yearly_registered_patients = {
        "name" => "Registered patients",
        "total" => 810,
        "breakdown" => [
          { "title" => "Hypertension only", "value" => 567, "row_type" => :header },
          { "title" => "Male", "value" => 277, "row_type" => :secondary },
          { "title" => "Female", "value" => 282, "row_type" => :secondary },
          { "title" => "Transgender", "value" => 8, "row_type" => :secondary },
          { "title" => "Diabetes only", "value" => 201, "row_type" => :header },
          { "title" => "Male", "value" => 115, "row_type" => :secondary },
          { "title" => "Female", "value" => 83, "row_type" => :secondary },
          { "title" => "Transgender", "value" => 3, "row_type" => :secondary },
          { "title" => "Hypertension and diabetes", "value" => 42, "row_type" => :header },
          { "title" => "Male", "value" => 27, "row_type" => :secondary },
          { "title" => "Female", "value" => 15, "row_type" => :secondary },
          { "title" => "Transgender", "value" => 0, "row_type" => :secondary },
        ]
      }
      @yearly_follow_up_patients = {
        "name" => "Follow-up patients",
        "total" => 1422,
        "breakdown" => [
          { "title" => "Hypertension only", "value" => 456, "row_type" => :header },
          { "title" => "Male", "value" => 220, "row_type" => :secondary },
          { "title" => "Female", "value" => 230, "row_type" => :secondary },
          { "title" => "Transgender", "value" => 6, "row_type" => :secondary },
          { "title" => "Diabetes only", "value" => 504, "row_type" => :header },
          { "title" => "Male", "value" => 250, "row_type" => :secondary },
          { "title" => "Female", "value" => 245, "row_type" => :secondary },
          { "title" => "Transgender", "value" => 9, "row_type" => :secondary },
          { "title" => "Hypertension and diabetes", "value" => 462, "row_type" => :header },
          { "title" => "Male", "value" => 224, "row_type" => :secondary },
          { "title" => "Female", "value" => 230, "row_type" => :secondary },
          { "title" => "Transgender", "value" => 8, "row_type" => :secondary },
        ]
      }
      @yearly_periods = ["2022", "2021", "2020", "2019"]
      render "api/v3/analytics/user_analytics/show_v2"
    else
      render "api/v3/analytics/user_analytics/show"
    end
  end

  helper_method :current_facility, :current_user, :current_facility_group

  private

  def current_facility
    @region.source
  end

  def current_user
    current_admin
  end

  def current_facility_group
    current_facility.facility_group
  end

  def require_feature_flag
    if !current_admin.feature_enabled?(:dashboard_progress_reports)
      user_not_authorized
      nil
    end
  end

  def find_region
    @region ||= authorize {
      current_admin.accessible_facility_regions(:view_reports).find_by!(slug: report_params[:id])
    }
  end

  def report_params
    params.permit(:id, :bust_cache, :v2, :report_scope, {period: [:type, :value]})
  end

  def set_period
    period_params = report_params[:period].presence || Reports.default_period.attributes
    @period = Period.new(period_params)
  end
end
