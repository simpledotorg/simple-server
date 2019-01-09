class Api::Current::Analytics::UserAnalyticsController < APIController
  def show
    Groupdate.time_zone = "New Delhi"

    @weeks_previous = 4
    @stats_for_user = new_patients_by_facility_week

    # Reset when done
    Groupdate.time_zone = "UTC"

    respond_to do |format|
      format.html { render :show }
      format.json { render json: @stats_for_user }
    end
  end

  private

  def new_patients_by_facility_week
    Facility.joins(:patients) \
      .where("facilities.id = '#{current_facility.id}'") \
      .distinct('patients.id') \
      .group_by_week('patients.device_created_at', last: @weeks_previous) \
      .count
  end
end
