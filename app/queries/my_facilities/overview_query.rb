# frozen_string_literal: true

class MyFacilities::OverviewQuery
  INACTIVITY_THRESHOLD_PERIOD = 1.week.ago
  INACTIVITY_THRESHOLD_BPS = 10

  def initialize(facilities = Facility.all)
    @facilities = facilities
  end

  def inactive_facilities
    facilities = @facilities.left_outer_joins(:blood_pressures)
                            .where('blood_pressures.recorded_at IS NULL OR blood_pressures.recorded_at > ?',
                              INACTIVITY_THRESHOLD_PERIOD)
                            .having('COUNT(blood_pressures) < ? ', INACTIVITY_THRESHOLD_BPS)
                            .group('facilities.id')

    Facility.where(id: facilities.pluck(:id))
  end
end
