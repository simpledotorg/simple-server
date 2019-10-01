class DistrictAnalyticsQuery
  include DashboardHelper
  attr_reader :facilities

  def initialize(district_name, facilities, period = :month, prev_periods = 3)
    @period = period
    @prev_periods = prev_periods
    @facilities = facilities
    @district_name = district_name
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
        .group('facilities.id', date_truncate_sql('patients', 'recorded_at', @period))
        .count

    group_by_facility_and_date(@registered_patients_by_period, :registered_patients_by_period)
  end

  def follow_up_patients_by_period
    date_truncate_string = date_truncate_sql('blood_pressures', 'recorded_at', @period)

    @follow_up_patients_by_period ||=
      BloodPressure
        .select('facilities.id AS facility_id',
                date_truncate_string,
                'count(blood_pressures.id) AS blood_pressures_count')
        .left_outer_joins(:user)
        .left_outer_joins(:patient)
        .joins(:facility)
        .where(facilities: { id: facilities })
        .group('facilities.id', date_truncate_string)
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
        .group('facilities.id::uuid', date_truncate_sql('call_logs', 'end_time', @period))
        .count

    group_by_facility_and_date(@total_calls_made_by_period, :total_calls_made_by_period)
  end

  private

  def date_truncate_sql(table, column, period)
    "(DATE_TRUNC('#{period}', #{table}.#{column}))::date"
  end

  def group_by_facility_and_date(query_results, key)
    valid_dates = dates_for_periods(@period, @prev_periods)

    query_results.map do |(facility_id, date), value|
      { facility_id => { key => { date => value }.slice(*valid_dates) } }
    end.inject(&:deep_merge)
  end
end
