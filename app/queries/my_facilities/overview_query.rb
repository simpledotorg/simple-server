# frozen_string_literal: true

class MyFacilities::OverviewQuery
  include DayHelper

  INACTIVITY_THRESHOLD_DAYS = 7
  INACTIVITY_THRESHOLD_BPS = 10

  def initialize(facilities = Facility.all)
    @facilities = facilities
  end

  def bps_in_last_n_days(n:)
    days_list = days_as_sql_list(last_n_days(n: n))
    BloodPressuresPerFacilityPerDay
        .select('facility_id, COUNT(bp_count)')
        .where("((year, day) IN (#{days_list})) OR day IS NULL")
        .having('COUNT(bp_count) < ?', INACTIVITY_THRESHOLD_BPS)
        .group(:facility_id)
  end

  def inactive_facilities
    facilities = @facilities.left_outer_joins(:blood_pressures)
                            .where('blood_pressures.recorded_at IS NULL OR blood_pressures.recorded_at > ?',
                                   INACTIVITY_THRESHOLD_DAYS.days.ago)
                            .having('COUNT(blood_pressures) < ? ', INACTIVITY_THRESHOLD_BPS)
                            .group('facilities.id')

    Facility.where(id: facilities.pluck(:id))
  end

  private

  def days_as_sql_list(days)
    days.map { |(year, day)| "('#{year}', '#{day}')" }.join(',')
  end
end
