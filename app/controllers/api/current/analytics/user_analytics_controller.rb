class Api::Current::Analytics::UserAnalyticsController < ApplicationController
  layout false

  WEEKS_TO_REPORT = 4

  def show
    @user_stats = mock_new_patients_by_facility_week

    respond_to do |format|
      format.html { render :show }
      format.json { render json: @user_stats }
    end
  end

  private

  def mock_new_patients_by_facility_week
    stats = {}

    now = Date.today
    previous_sunday = now - now.wday
    WEEKS_TO_REPORT.times do |n|
      stats[previous_sunday - n.weeks] = n * 5 + 3
    end

    stats
  end

  def new_patients_by_facility_week
    FacilitiesQuery.new.patients_registered_per_week(current_facility.id, WEEKS_TO_REPORT)
  end
end