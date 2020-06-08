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

  def total_registered_patients
    @total_registered_patients ||=
      Patient
        .with_hypertension
        .joins(:registration_facility)
        .where(facilities: { id: facilities })
        .group('facilities.id')
        .count

    return if @total_registered_patients.blank?

    @total_registered_patients
      .map { |facility_id, count| [facility_id, { :total_registered_patients => count }] }
      .to_h
  end

  def registered_patients_by_period
    @registered_patients_by_period ||=
      Patient
        .with_hypertension
        .joins(:registration_facility)
        .where(facilities: { id: facilities })
        .group('facilities.id')
        .group_by_period(@period, :recorded_at)
        .count

    group_by_facility_and_date(@registered_patients_by_period, :registered_patients_by_period)
  end

  def follow_up_patients_by_period
    @follow_up_patients_by_period ||=
      Patient
        .group('blood_pressures.facility_id')
        .hypertension_follow_ups_by_period(@period, last: @prev_periods)
        .where(blood_pressures: { facility: facilities })
        .count

    group_by_facility_and_date(@follow_up_patients_by_period, :follow_up_patients_by_period)
  end

  private

  def group_by_facility_and_date(query_results, key)
    valid_dates = dates_for_periods(@period,
                                    @prev_periods,
                                    from_time: @from_time,
                                    include_current_period: @include_current_period)

    query_results.map do |(facility_id, date), value|
      { facility_id => { key => { date => value }.slice(*valid_dates) } }
    end.inject(&:deep_merge)
  end
end
