class Api::V3::Analytics::UserAnalyticsController < Api::V3::AnalyticsController
  include ApplicationHelper
  include SetForEndOfMonth
  before_action :set_for_end_of_month
  before_action :set_bust_cache

  layout false

  def show
    @user_analytics = UserAnalyticsPresenter.new(current_facility)
    @period = Period.month(@for_end_of_month)
    if current_user.feature_enabled?(:follow_ups_v2_progress_tab)
      @service = Reports::FacilityProgressService.new(current_facility, @period)
    end

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
    end

    respond_to do |format|
      if Flipper.enabled?(:new_progress_tab)
        format.html { render :show_v2 }
      else
        format.html { render :show }
      end
      format.json { render json: @user_analytics.statistics }
    end
  end

  helper_method :current_facility, :current_user, :current_facility_group

  private

  def set_bust_cache
    RequestStore.store[:bust_cache] = true if params[:bust_cache].present?
  end
end
