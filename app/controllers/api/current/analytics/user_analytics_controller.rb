class Api::Current::Analytics::UserAnalyticsController < APIController
  layout false

  def show
    Groupdate.time_zone = "New Delhi"

    @weeks_previous = 4
    @stats_for_user = mock_new_patients_by_facility_week

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

  def mock_new_patients_by_facility_week
    stats = {}

    now = Date.today
    previous_sunday = now - now.wday
    @weeks_previous.times do |n|
      stats[previous_sunday - n.weeks] = n * 5 + 3
    end

    stats
  end
end
