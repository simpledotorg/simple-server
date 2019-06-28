class DistrictAnalyticsQuery
  def initialize(district_name)
    @district_name = district_name
  end

  def total_registered_patients
    return if registered_patients_by_month.blank?

    registered_patients_by_month.map do |facility_id, facility_analytics|
      [facility_id, { :total_registered_patients => facility_analytics[:registered_patients_by_month].values.sum }]
    end.to_h
  end

  def registered_patients_by_month
    @registered_patients_by_month ||=
      Patient
        .joins(:registration_facility)
        .where(facilities: { district: @district_name })
        .group('facilities.id', date_truncate_sql('patients', 'device_created_at', period: 'month'))
        .count

    group_by_facility_and_date(@registered_patients_by_month, :registered_patients_by_month)
  end

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
        .where(facilities: { district: @district_name })
        .group('facilities.id', date_truncate_string)
        .where("patients.device_created_at < #{date_truncate_string}")
        .order('facilities.id')
        .distinct
        .count('patients.id')

    group_by_facility_and_date(@follow_up_patients_by_month, :follow_up_patients_by_month)
  end

  private

  def date_truncate_sql(table, column, period: 'month')
    "(DATE_TRUNC('#{period}', #{table}.#{column}))::date"
  end

  def group_by_facility_and_date(query_results, key)
    query_results.map do |(facility_id, date), value|
      { facility_id => { key => { date => value } } }
    end.inject(&:deep_merge)
  end
end
