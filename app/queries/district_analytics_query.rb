class DistrictAnalyticsQuery
  def initialize(district_name:)
    @district_name = district_name
  end

  def total_registered_patients
    registered_patients_by_month.map do |facility_id, facility_analytics|
      [facility_id, { :total_registered_patients => facility_analytics[:registered_patients_by_month].values.sum } ]
    end.to_h
  end

  def registered_patients_by_month
    @registered_patients_by_month ||=
      Patient
        .joins(:registration_facility)
        .where(facilities: { district: @district_name })
        .group('facilities.id')
        .group_by_month(:device_created_at)
        .count

    group_by_facility_and_date(@registered_patients_by_month, :registered_patients_by_month)
  end

  def follow_up_patients_by_month
    @follow_up_patients_by_month ||=
      BloodPressure
        .select('facilities.id AS facility_id',
                "(DATE_TRUNC('month', (blood_pressures.device_created_at::timestamptz) AT TIME ZONE 'Etc/UTC')) AT TIME ZONE 'Etc/UTC'",
                'count(blood_pressures.id) AS blood_pressures_count')
        .left_outer_joins(:user)
        .left_outer_joins(:patient)
        .joins(:facility)
        .where(facilities: { district: @district_name })
        .group('facilities.id')
        .group_by_month('blood_pressures.device_created_at')
        .where("patients.device_created_at < DATE_TRUNC('month', blood_pressures.device_created_at::timestamptz)")
        .order('facilities.id')
        .distinct
        .count('patients.id')

    group_by_facility_and_date(@follow_up_patients_by_month, :follow_up_patients_by_month)
  end

  private

  def group_by_facility_and_date(query_results, key)
    query_results.map do |(facility_id, date), value|
      { facility_id => { key => { date => value } } }
    end.inject(&:deep_merge)
  end
end
