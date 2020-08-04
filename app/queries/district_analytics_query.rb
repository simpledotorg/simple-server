class DistrictAnalyticsQuery
  include DashboardHelper
  attr_reader :facilities

  def initialize(district_name, facilities, period = :month, prev_periods = 3, from_time = Time.current,
    include_current_period: false)

    @period = period
    @prev_periods = prev_periods
    @facilities = facilities
    @district_name = district_name
    @from_time = from_time
    @include_current_period = include_current_period
  end

  def total_assigned_patients
    @total_assigned_patients ||=
      Patient
        .with_hypertension
        .joins(:assigned_facility)
        .where(facilities: {id: facilities})
        .group("facilities.id")
        .count

    return if @total_assigned_patients.blank?

    @total_assigned_patients
      .map { |facility_id, count| [facility_id, {total_assigned_patients: count}] }
      .to_h
  end

  def registered_patients_by_period
    @registered_patients_by_period ||=
      Patient
        .with_hypertension
        .joins(:registration_facility)
        .where(facilities: {id: facilities})
        .group("facilities.id")
        .group_by_period(@period, :recorded_at)
        .count

    group_by_facility_and_date(@registered_patients_by_period, :registered_patients_by_period)
  end

  def assigned_patient_visits_by_period
    @assigned_patient_visits_by_period ||=
      Patient
        .group("assigned_facility_id")
        .where(assigned_facility: facilities)
        .hypertension_follow_ups_by_period(@period, last: @prev_periods)
        .count

    group_by_facility_and_date(@assigned_patient_visits_by_period, :assigned_patient_visits_by_period)
  end

  private

  def group_by_facility_and_date(query_results, key)
    valid_dates = dates_for_periods(@period,
      @prev_periods,
      from_time: @from_time,
      include_current_period: @include_current_period)

    query_results.map { |(facility_id, date), value|
      {facility_id => {key => {date => value}.slice(*valid_dates)}}
    }.inject(&:deep_merge)
  end
end
