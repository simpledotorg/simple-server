class Api::Current::AnalyticsController < APIController
  def index
    Groupdate.time_zone = "New Delhi"

    @weeks_previous = 4
    @stats_for_facility = new_patients_by_facility_week
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
