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
        .joins(:registration_facility)
        .where(facilities: { id: facilities })
        .group('facilities.id')
        .group_by_period(@period, :recorded_at)
        .count

    group_by_facility_and_date(@registered_patients_by_period, :registered_patients_by_period)
  end

  def follow_up_patients_by_period
    #
    # this is similar to what the group_by_period query already gives us,
    # however, groupdate does not allow us to use these "groups" in a where clause
    # hence, we've replicated its grouping behaviour in order to remove the patients
    # that were registered prior to the period bucket
    #
    date_truncate_string =
      "(DATE_TRUNC('#{@period}', blood_pressures.recorded_at::timestamptz AT TIME ZONE '#{Groupdate.time_zone || 'Etc/UTC'}'))"

    @follow_up_patients_by_period ||=
      BloodPressure
        .left_outer_joins(:user)
        .left_outer_joins(:patient)
        .joins(:facility)
        .where(facilities: { id: facilities })
        .where(deleted_at: nil)
        .group('facilities.id')
        .group_by_period(@period, 'blood_pressures.recorded_at')
        .where("patients.recorded_at < #{date_truncate_string}")
        .order('facilities.id')
        .distinct
        .count('patients.id')

    group_by_facility_and_date(@follow_up_patients_by_period, :follow_up_patients_by_period)
  end

  def total_calls_made_by_period
    @total_calls_made_by_period ||=
      CallLog
        .result_completed
        .joins('INNER JOIN phone_number_authentications ON phone_number_authentications.phone_number = call_logs.caller_phone_number')
        .joins('INNER JOIN facilities ON facilities.id = phone_number_authentications.registration_facility_id')
        .where(phone_number_authentications: { registration_facility_id: facilities })
        .group('facilities.id::uuid')
        .group_by_period(@period, :end_time)
        .count

    group_by_facility_and_date(@total_calls_made_by_period, :total_calls_made_by_period)
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
