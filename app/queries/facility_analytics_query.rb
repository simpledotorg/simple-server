class FacilityAnalyticsQuery
  def initialize(facility)
    @facility = facility
  end

  def total_registered_patients
    return if registered_patients_by_month.blank?

    registered_patients_by_month.map do |user_id, facility_analytics|
      [user_id, { :total_registered_patients => facility_analytics[:registered_patients_by_month].values.sum }]
    end.to_h
  end

  def registered_patients_by_month
    @registered_patients_by_month ||=
      Patient
        .joins(:registration_facility)
        .joins('INNER JOIN blood_pressures ON blood_pressures.facility_id = patients.registration_facility_id')
        .where(registration_facility: @facility)
        .group('registration_user_id', date_truncate_sql('patients', 'device_created_at', period: 'month'))
        .distinct('patients.id')
        .count

    group_by_user_and_date(@registered_patients_by_month, :registered_patients_by_month)
  end

  # NOTE: temporary usage of master_users (instead of users table) until users migration is finished
  def follow_up_patients_by_month
    date_truncate_string = date_truncate_sql('blood_pressures', 'device_created_at', period: 'month')

    @follow_up_patients_by_month ||=
      BloodPressure
        .select('facilities.id AS facility_id',
                date_truncate_string,
                'count(blood_pressures.id) AS blood_pressures_count')
        .left_outer_joins(:user)
        .left_outer_joins(:patient)
        .joins(:facility)
        .where(facility: @facility)
        .group('master_users.id', date_truncate_string)
        .where("patients.device_created_at < #{date_truncate_string}")
        .order('master_users.id')
        .distinct
        .count('patients.id')

    group_by_user_and_date(@follow_up_patients_by_month, :follow_up_patients_by_month)
  end

  private

  def date_truncate_sql(table, column, period: 'month')
    "(DATE_TRUNC('#{period}', #{table}.#{column}))::date"
  end

  def group_by_user_and_date(query_results, key)
    query_results.map do |(user_id, date), value|
      { user_id => { key => { date => value } } }
    end.inject(&:deep_merge)
  end
end
