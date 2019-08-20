class DistrictAnalyticsQuery
  def initialize(district_name, organization, time_period = :month)
    @district_name = district_name
    @time_period = time_period
    @organization = organization
  end

  def total_registered_patients
    return if registered_patients_by_period.blank?

    registered_patients_by_period.map do |facility_id, facility_analytics|
      [facility_id, { :total_registered_patients => facility_analytics[:registered_patients_by_period].values.sum }]
    end.to_h
  end

  def registered_patients_by_period
    @registered_patients_by_period ||=
      Patient
        .joins(:registration_facility)
        .where(facilities: { id: facilities })
        .group('facilities.id', date_truncate_sql('patients', 'recorded_at', @time_period))
        .count

    group_by_facility_and_date(@registered_patients_by_period, :registered_patients_by_period)
  end

  def follow_up_patients_by_period
    date_truncate_string = date_truncate_sql('blood_pressures', 'recorded_at', @time_period)

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
        .group('facilities.id::uuid', date_truncate_sql('call_logs', 'end_time', @time_period))
        .count

    group_by_facility_and_date(@total_calls_made_by_period, :total_calls_made_by_period)
  end

  def total_calls_made_by_month
    @total_calls_made_by_month ||=
      CallLog
        .result_completed
        .joins('INNER JOIN phone_number_authentications ON phone_number_authentications.phone_number = call_logs.caller_phone_number')
        .joins('INNER JOIN facilities ON facilities.id = phone_number_authentications.registration_facility_id')
        .where(phone_number_authentications: { registration_facility_id: facilities })
        .group('facilities.id::uuid', date_truncate_sql('call_logs', 'end_time', period: 'month'))
        .count

    group_by_facility_and_date(@total_calls_made_by_month, :total_calls_made_by_month)
  end

  private

  def date_truncate_sql(table, column, period)
    "(DATE_TRUNC('#{period}', #{table}.#{column}))::date"
  end

  def group_by_facility_and_date(query_results, key)
    query_results.map do |(facility_id, date), value|
      { facility_id => { key => { date => value } } }
    end.inject(&:deep_merge)
  end

  def facilities
    @organization.facilities.where(district: @district_name)
  end
end
